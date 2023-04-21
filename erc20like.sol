
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";

contract erc20like is Ownable {
    string private _name;
    string private _symbol;

    uint8 private _decimals = 18;
    uint256 private _totalSupply = 100000000000000000000;
    uint8 private _taxValue = 5;

    address private _owner;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor(string memory name, string memory symbol) {
        _owner = msg.sender;
        _name = name;
        _symbol = symbol;
        _balances[_owner] = _totalSupply;
    }

    function getName() public view returns (string memory) {
        return _name;
    } 

    function getSymbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getAddress() public view returns (address) {
        return address(this);
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public payable returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true; //meaningless return !!!!???
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public payable returns (bool) {
        // is it correct to mark as payable functions with internal taxing?????
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 value) public returns (bool) {
        address owner = msg.sender;
        uint256 allowanceValue = allowance(owner, spender);
        _approve(owner, spender, allowanceValue + value);
        return true;
    }

    function decreaseAllowance(address spender, uint256 value) public returns (bool) {
        address owner = msg.sender;
        uint256 allowanceValue = allowance(owner, spender);
        require(allowanceValue >= value, 'decreased value below zero');
        _approve(owner, spender, allowanceValue - value);
        return true;
    }



    function _transfer(address from, address to, uint256 amount) internal {
        uint256 fromBalance = _balances[from];
        uint256 tax = _tax(amount);
        require(fromBalance >= amount + tax, "Unsufficient balance = ");
        unchecked {
            _balances[from] = fromBalance - amount - tax;
            _balances[to] += amount;
            _balances[_owner] += tax;
        }
        emit Transfer(from, to, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if(currentAllowance != type(uint256).max) { // what for this condition???
            require(currentAllowance >= amount, "insufficient allowance");
            unchecked {
                _approve(owner, spender, amount);
            }
        }
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), 'Mint to zero address');
        _totalSupply += amount;
        unchecked {
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), 'Burn from zero address');
        uint256 accountBalance = _balances[account];
        require(accountBalance > amount, 'insufficient balance');
        _totalSupply -= amount;
        unchecked {
            _balances[account] -= amount;
        }
        emit Transfer(account, address(0), amount);
    }

    function _tax(uint256 amount) internal pure returns (uint256){
        return amount * _taxValue / 100;
    }

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed from, address to, uint256 amount);
}