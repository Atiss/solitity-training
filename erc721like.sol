
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/Context.sol";

interface erc721likeReceiver {
    function onErc721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

struct Item {
    address seller;
    uint256 price;
}

contract erc721like is Context {
    string private _name;
    string private _symbol;
    string private _baseURI = 'https://ipfs.io/ipfs/QmNoG4xFu7cB7dQLRyp5jwy7T9wnCsVyBUw2HKzpJnk1J6?filename=';
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _owners;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => Item) private _items;

    uint256 private _counter = 0;

    constructor(string memory name, string memory symbol) {
        _name = name;
        _symbol = symbol;
    }

    function createItem(address payable to) public {
        _counter+=1;
        _mint(to, _counter);
        _setTokenURI(_counter, _encodeTokenURI(_counter));
    }

    function listItem(uint256 tokenId, uint256 price) public {
        require(_owners[tokenId] == _msgSender(), 'Not an owner');
        _items[tokenId] = Item(_msgSender(), price);
        emit ItemListed(tokenId, _msgSender(), price);
    }

    function buyItem(uint256 tokenId) public payable {
        require(_owners[tokenId] != _msgSender(), 'Token owner');
        require(_items[tokenId].seller != address(0), 'Token not for sale');
        uint256 price = _items[tokenId].price;
        require(msg.value >= price, 'Not enough payment');
        payable(_owners[tokenId]).transfer(msg.value);
        safeTransferFrom(_owners[tokenId], payable(_msgSender()), tokenId);
        delete _items[tokenId];
        emit ItemBought(tokenId, _owners[tokenId], price);
    }

    function cancel(uint256 tokenId) public {
        require(_owners[tokenId] == _msgSender(), 'Not an owner');
        delete _items[tokenId];
        emit ItemCancelled(tokenId, _owners[tokenId]);
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        return _owners[tokenId];
    }

    function approve(address to, uint256 tokenId) public {
        address owner = _owners[tokenId];
        require(to != owner, 'Cannot approve to myself');
        require(_msgSender() == owner, 'Approve sender is not owner');
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId) != false, 'Invalid token id');
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public {
        address owner = _msgSender();
        require (operator != owner, 'Owner cannot be operator');
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address payable to, uint256 tokenId) public {
        require(_isApprovedOwner(_msgSender(), tokenId), 'Caller is not owner');
        _transfer(_msgSender(), to, tokenId);
    }

    function safeTransferFrom(address from, address payable to, uint256 tokenId) public {
        require(_isApprovedOwner(_msgSender(), tokenId), 'Caller is not owner');
        _transfer(from, to, tokenId);
        require(_checkOnERC721Receiver(from, to, tokenId, ''), 'Transfer to non erc721likeReceiver');
    }

    function _exists(uint256 tokenId) private view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOwner(address spender, uint256 tokenId) private view returns (bool) {
        return _msgSender() == spender || getApproved(tokenId) == spender || isApprovedForAll(_msgSender(), spender);
    }

    function _transfer(address from, address payable to, uint256 tokenId) private {
        require(_owners[tokenId] == from, 'Caller is not owner');
        delete _tokenApprovals[tokenId];
        _owners[tokenId] = to;
        _balances[from] -= 1;
        _balances[to] +=1;
        emit Transfer(from, to, tokenId); 
    }

    function _checkOnERC721Receiver(address from, address to, uint256 tokenId, bytes memory data) private returns (bool){
        if (to.code.length > 0) {
            try erc721likeReceiver(to).onErc721Received(_msgSender(), from, tokenId, data) returns (bytes4 returnVal) {
                return returnVal == erc721likeReceiver.onErc721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert('Transfer to non erc721 receiver');
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _mint(address payable to, uint256 tokenId) internal {
        require(!_exists(tokenId), 'Token is already minted');
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }

    function _safeMint(address payable to, uint256 tokenId) internal {
        _mint(to, tokenId);
        require(_checkOnERC721Receiver(address(0), to, tokenId, ''), 'Transfer to non erc721likeReceiver');
    }

    function _burn(uint256 tokenId) internal {
        address owner = _owners[tokenId];
        delete _tokenApprovals[tokenId];
        _balances[owner] -= 1;
        delete _owners[tokenId];
        emit Transfer(owner, address(0), tokenId);
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), 'Token is exist');
        _tokenURIs[tokenId] = _tokenURI;

        emit MetadataUpdate(tokenId);
    }

    function _encodeTokenURI(uint256 tokenId) private view returns (string memory) {
        return string(abi.encodePacked(_baseURI, tokenId, '.json'));
    }


    event Approval(address indexed from, address indexed to, uint256 tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event Transfer(address indexed from, address indexed to, uint256 tokenId);
    event MetadataUpdate(uint256 tokenId);
    event ItemListed(uint256 tokenId, address indexed from, uint256 price);
    event ItemBought(uint256 tokenId, address indexed to, uint256 price);
    event ItemCancelled(uint256 tokenId, address indexed owner);
}