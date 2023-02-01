/**
 *Submitted for verification at Etherscan.io on 2017-11-28
*/

pragma solidity ^0.8;


abstract contract ERC20Basic {
    uint public _totalSupply;
    function totalSupply() public virtual returns (uint);
    function balanceOf(address who) public virtual returns (uint);
    function transfer(address to, uint value) public virtual;
    event Transfer(address indexed from, address indexed to, uint value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
abstract contract  ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public virtual  returns (uint);
    function transferFrom(address from, address to, uint value) public virtual;
    function approve(address spender, uint value) public virtual;
    event Approval(address indexed owner, address indexed spender, uint value);
}