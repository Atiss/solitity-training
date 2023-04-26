
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC721//ERC721.sol";

struct Item {
    address seller;
    uint256 price;
}

contract erc721like is ERC721 {
    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => Item) private _items;

    uint256 private _counter = 0;

    constructor() ERC721("THEROMATOKEN", "ROM") {

    }

    function createItem(address payable to, string memory tokenUri) public {
        _counter+=1;
        _mint(to, _counter);
        _setTokenURI(_counter, tokenUri);
    }

    function listItem(uint256 tokenId, uint256 price) public {
        require(ownerOf(tokenId) == _msgSender(), 'Not an owner');
        _items[tokenId] = Item(_msgSender(), price);
        emit ItemListed(tokenId, _msgSender(), price);
    }

    function buyItem(uint256 tokenId) public payable {
        require(ownerOf(tokenId) != _msgSender(), 'Token owner');
        require(_items[tokenId].seller != address(0), 'Token not for sale');
        uint256 price = _items[tokenId].price;
        require(msg.value >= price, 'Not enough payment');
        payable(ownerOf(tokenId)).transfer(msg.value);
        _safeTransfer(ownerOf(tokenId), payable(_msgSender()), tokenId, "");
        delete _items[tokenId];
        emit ItemBought(tokenId, ownerOf(tokenId), price);
    }

    function cancel(uint256 tokenId) public {
        require(ownerOf(tokenId) == _msgSender(), 'Not an owner');
        delete _items[tokenId];
        emit ItemCancelled(tokenId, ownerOf(tokenId));
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Token doesn't exist");
        return _tokenURIs[tokenId];
    }


    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "Token doesn't exist");
        _tokenURIs[tokenId] = _tokenURI;

        emit MetadataUpdate(tokenId);
    }

    event MetadataUpdate(uint256 tokenId);
    event ItemListed(uint256 tokenId, address indexed from, uint256 price);
    event ItemBought(uint256 tokenId, address indexed to, uint256 price);
    event ItemCancelled(uint256 tokenId, address indexed owner);
}