// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Console.sol";
contract test {

    using SafeMath for uint256;

    uint256 public startTime;
    uint256 public endTime;
    uint256 public singleSliceSecond;
    uint256 public slices;
    uint256 public amountToHold;
    uint256 public lastValue;
    

    constructor() {
    }

    address[] private whiteListAddresses;
    mapping(address => bool) public iswhitelist;


    function addWhitelist(address[] memory _userAddress) public {
        
        for (uint256 count = 0; count < _userAddress.length; count++) {    
            require(!iswhitelist[_userAddress[count]], "already Whitelisted");
            whiteListAddresses.push(_userAddress[count]);
            iswhitelist[_userAddress[count]] = true; 
        }
    }

    function removeWhitelist(address[] memory _userAddress) public {
        for (uint256 count = 0; count < _userAddress.length; count++) {    
            
            for(uint256 i=0; i<= whiteListAddresses.length; i++){
                if(whiteListAddresses[i] == _userAddress[count]){
                    iswhitelist[_userAddress[count]] = false;
                    removeFromarray(i);
                    break;
                }
            }

        }

    }

    function removeFromarray(uint256 index) private {
        address temp = whiteListAddresses[index];
        whiteListAddresses[index] = whiteListAddresses[whiteListAddresses.length-1];
        whiteListAddresses[whiteListAddresses.length-1]= temp;
        whiteListAddresses.pop();
    }



    function whitelistCount() public view returns(uint256 _length){
        _length = whiteListAddresses.length;
    }

    address[] contributorAddresses ;
    function addAddress(address _userAddress) public {
        contributorAddresses.push(_userAddress);
    }
    
    function getCompleteAddressList(uint256 page, uint256 size) public view returns (address[] memory _userAddresses){
        uint256 ToSkip = page * size; //to skip
        uint256 count = 0;

        uint256 EndAt = contributorAddresses.length > ToSkip + size ? ToSkip + size : contributorAddresses.length;

        if(ToSkip < contributorAddresses.length && EndAt > ToSkip){

            address[] memory result = new address[](EndAt - ToSkip);

            for (uint256 i = ToSkip; i < EndAt; i++) {
                result[count] = contributorAddresses[i];
                count++;
            }
            return result;
        }
    }

    
    receive() external payable {}
    fallback() external payable {}

}