// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract Test1155 is ERC1155, Ownable {
    mapping(address => bool) private _whiteList;

    constructor() ERC1155("ipfs://bafkreiea6au3c5ckupkw24ikcdcexrnyf5rnmf3niffbv5im4uyql4bguu") {}

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data) public onlyOwner {
        _mint(account, id, amount, data);
    }

    function buyNft(uint256 id, uint256 amount) public payable {
        require(msg.value >= 0.1 ether, 'Not enough payment');
        require(_whiteList[_msgSender()] == true, 'You are not allowed to buy NFT');
        _mint(_msgSender(), id, amount, '');
    }

    function addWhitlist(address addr, bool isAdd) public {
        _whiteList[addr] = isAdd;
    }

}