// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract INV_Seed is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    ///////////////////// Variables ///////////////////////
    using SafeMath for uint256;
    
    mapping(address => uint256) public USDTDeposites;
    mapping(address => uint256) public OGBDelivered;
    mapping(address => uint256) public beforeVestingTokens;
    mapping(address => bool) public isOperator;
    mapping(address => uint256) private lastWithdrawSlice;
    mapping(address => uint256) public lastWithdrawAmount;
    
    //address[] private whiteListAddresses;
    //mapping(address => bool) public iswhitelist;

    address public USDTAddress;
    address public OGBAddress;
    address public devWallet;
    address public OwnerWallet;
    address public launchContract;
    uint256 public noOfSlices;
    uint256 public USDT_To_OGB_Rate;
    uint256 public tokenGenPercentage;
    uint256 public devFee;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public bookedTokens;
    uint256 public timePeriod;
    uint256 public sliceTime;
    uint256 public usdtLimit;
    uint256 public collectedUsdt;
    bool public isICOStart;
    bool public isICOLaunch;
    bool public isStartedOnce;


    event currentSliceStatus(uint256 _slice, uint256 _amount);

    constructor() {
        _disableInitializers();
    }

    function initialize(address _USDTAddress, address _OGBAddress, address _launchContract) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        USDTAddress = _USDTAddress;
        OGBAddress = _OGBAddress;
        launchContract = _launchContract;
        USDT_To_OGB_Rate = 18000000000000000; //0.018 USDT to 1 $OGB 18*10**-12;
        tokenGenPercentage = 5250000000000000000; // 5.25%
        devFee = 10000000000000000; //1%
        OwnerWallet = 0x621c550FA486Ae3ae50D19405eD88ad175939774;
        devWallet = 0xd5D346E702caB96382dD5E77B6050Cb754B69801;
        usdtLimit = 198000*10**18;
        isOperator[msg.sender] = true;
        //isWhiteList[msg.sender] = true;
        noOfSlices = 36;
        timePeriod = 10800;
        //timePeriod = 21600;
        //sliceTime = 600;
        sliceTime = 300;
    }

    function setSliceTime(uint256 _timeSeconds) public onlyOwner{
        sliceTime = _timeSeconds;
    }

    function setUSDTLimit(uint256 _amount) public onlyOwner{
        usdtLimit = _amount;
    }

    function setOwnerWallet(address _ownerAddress) public onlyOwner{
        OwnerWallet = _ownerAddress;
    }
    
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function StartICO() public{
        require(isOperator[msg.sender], "only Operator");
        require(!isStartedOnce,"can not be started again");
        isICOStart = true;
    }

    function StopICO() public{
        require(isOperator[msg.sender], "only Operator");
        isICOStart = false;
        isStartedOnce = true;
    }
    
    function setUSDT_OBG_Rate(uint256 _rate) public onlyOwner{
        USDT_To_OGB_Rate = _rate;
    }

    //Send USDT to contract and get OGBToken
    function deposit(uint256 _amount) public {
        //require(getWhiteLists(msg.sender), "you are not whitelisted");
        require(!isICOLaunch, "Token launched, cannot deposit");
        require(isICOStart, "wait to start ICO");
        require(_amount > 0, "Amount must be greater than zero");
        require(collectedUsdt+_amount <= usdtLimit, "OUt of depth error" );
        collectedUsdt += _amount;
        uint256 _devAmount = (_amount.mul(devFee))/10**18;
        //uint256 OGBTokenAmount = ((_amount.mul(10**18)).div(USDT_To_OGB_Rate));
        uint256 accurateOGBToken = getAccurateResult(_amount);
        //require(accurateOGBToken + bookedTokens <= IERC20(OGBAddress).balanceOf(address(this)),"require amount more than available balance");
        bookedTokens += accurateOGBToken;
        uint256 _remaingAmount = _amount - _devAmount;
        IERC20(USDTAddress).transferFrom(msg.sender, devWallet, _devAmount);
        IERC20(USDTAddress).transferFrom(msg.sender, OwnerWallet, _remaingAmount);
        USDTDeposites[msg.sender] += _amount;
       
        uint256 accurateBeforeVestingT = getAccurateResult2(accurateOGBToken);
        beforeVestingTokens[msg.sender] += accurateBeforeVestingT;
        OGBDelivered[msg.sender] += accurateOGBToken - accurateBeforeVestingT;
    }

    function getAccurateResult(uint256 _amount) private view returns(uint256 _result) {
        
        uint256 OGBToken = ((_amount.mul(10**18)).div(USDT_To_OGB_Rate));
        
        uint256 step1 = OGBToken/10; //5879
        uint256 step2 = step1 * 10;//58790
        uint256 step3 = OGBToken - step2;
        
        if(step3 >4){
            //if(((_amount.mul(10**18)).div(USDT_To_OGB_Rate)) % 2 == 1){
                _result = (((_amount.mul(10**2).add(1)).mul(10**18)).div(USDT_To_OGB_Rate))/10**2;    
            //}
        }
        else{
            _result = ((_amount.mul(10**18)).div(USDT_To_OGB_Rate));
        }
    }
    function getAccurateResult2(uint256 OGBToken) private view returns(uint256 _result) {
        
        uint256 step1 = OGBToken/10; //5879
        uint256 step2 = step1 * 10;//58790
        uint256 step3 = OGBToken - step2;
        if(step3 >4){
            
            _result = ((OGBToken.add(10)).mul(tokenGenPercentage))/10**20;
        }
        else{  
        _result = (OGBToken.mul(tokenGenPercentage))/10**20;
        }
    }
    function getUserAmounts(address _userAddress) public view returns(uint256 _totalOGBTokens, uint256 _beforeVestingToken, uint256 _perSliceTokens){
        _totalOGBTokens = OGBDelivered[_userAddress];
        _beforeVestingToken = beforeVestingTokens[_userAddress];
        _perSliceTokens = (_totalOGBTokens).div(noOfSlices);
    }

    function setTimePeriod(uint256 _time) public onlyOwner{
        timePeriod = _time;
    }

    function Launch() public{
        require(launchContract == msg.sender || msg.sender == owner(), "you are not authorized");
        isICOLaunch = true;
        require(!isICOStart, "Stop the ICO");
        startTime = block.timestamp;
        endTime = startTime + timePeriod;
    }

    function setOperator(address _userAddress, bool flage) public onlyOwner{
        isOperator[_userAddress] = flage;
    }

    // function addWhitelist(address _userAddress) public {
    //     require(isOperator[msg.sender], "only Operator");
    //     require(!iswhitelist[_userAddress], "already Whitelisted");
    //     whiteListAddresses.push(_userAddress);
    //     iswhitelist[_userAddress] = true;
    // }

    // function removeWhitelist(address _userAddress) public {
    //     require(isOperator[msg.sender], "only Operator");
    //     for(uint256 i=0; i<= whiteListAddresses.length; i++){
    //         if(whiteListAddresses[i] == _userAddress){
    //             iswhitelist[_userAddress] = false;
    //             removeFromarray(i);
    //             break;
    //         }
    //     }
    // }

    // function getCompleteAddressList(uint256 page, uint256 size) public view
    // returns (address[] memory)
    // {
    //     uint256 ToSkip = page * size; //to skip
    //     uint256 count = 0;

    //     uint256 EndAt = whiteListAddresses.length > ToSkip + size
    //         ? ToSkip + size
    //         : whiteListAddresses.length;

    //     require(ToSkip < whiteListAddresses.length, "OUT OF RANGE");
    //     require(EndAt > ToSkip,  "OUT OF RANGE");
    //     address[] memory result = new address[](EndAt - ToSkip);

    //     for (uint256 i = ToSkip; i < EndAt; i++) {
    //         result[count] = whiteListAddresses[i];
    //         count++;
    //     }
    //     return result;
    // }

    // function removeFromarray(uint256 index) private {
    //     address temp = whiteListAddresses[index];
    //     whiteListAddresses[index] = whiteListAddresses[whiteListAddresses.length-1];
    //     whiteListAddresses[whiteListAddresses.length-1]= temp;
    //     whiteListAddresses.pop();
    // }


    // function getWhiteLists(address _userAddress) public view returns(bool){
    //     return iswhitelist[_userAddress];
    // }

    // function getWhitelistCount() public view returns(uint256 _whitelistCount){
    //     _whitelistCount = whiteListAddresses.length;
    // }

    // function getAllWhitelist() public view returns(address[] memory _whitelist){
    //     _whitelist = whiteListAddresses;
    // }

    function setNumberOfSlices(uint256 _slices) public onlyOwner{
        noOfSlices = _slices;
    }

    function getVestedAmount(address _benifierAddress) public view returns(uint256 _beforeVestingAmount, uint256 _vestedAmount, uint256 slice) {
        if(OGBDelivered[_benifierAddress] > 0){
            (uint256 computedAmount, uint256 _slice) = _computeReleasableAmount(_benifierAddress);
            computedAmount = computedAmount.sub(lastWithdrawAmount[_benifierAddress]);

            _vestedAmount = computedAmount; 
            slice = _slice;
            _beforeVestingAmount = beforeVestingTokens[_benifierAddress];
        }
    }

    function release(address _benifierAddress) public {
        require(USDTDeposites[_benifierAddress] > 0, "plz deposit some usdt first");
        require(isICOLaunch, "Token is not launched");
        
        (uint256 _beforeVestingAmount, uint256 vestedAmount, uint256 slice) = getVestedAmount(_benifierAddress);

        if(slice > lastWithdrawSlice[_benifierAddress])
        {
            lastWithdrawSlice[_benifierAddress] = slice;
            lastWithdrawAmount[_benifierAddress] = lastWithdrawAmount[_benifierAddress].add(vestedAmount);
            if(_beforeVestingAmount > 0 ){
                IERC20(OGBAddress).transfer(_benifierAddress, _beforeVestingAmount);    
            }
            IERC20(OGBAddress).transfer(_benifierAddress, vestedAmount);
            beforeVestingTokens[_benifierAddress] = 0;
            emit currentSliceStatus(slice, vestedAmount);
        }
        else if(_beforeVestingAmount > 0){
            IERC20(OGBAddress).transfer(_benifierAddress, _beforeVestingAmount);
            beforeVestingTokens[_benifierAddress] = 0;
        }
        else{
            revert("You have already withdrawn the amount available");
        }
    }

    function _computeReleasableAmount(address _benifierAddress) private view returns(uint256, uint256){
        uint256 currentTime = block.timestamp; 
        uint256 timePassed;
        uint256 _amountToHold = OGBDelivered[_benifierAddress];

        if (currentTime >= endTime) {
            return (_amountToHold, noOfSlices);
        }
        else {
            timePassed = currentTime.sub(startTime);

            /////////////////////////////////// will be change to 30
            uint256 NumberOfSlicesPassed = timePassed.div(sliceTime);

            uint256 amountPerSlice = (_amountToHold).div(noOfSlices);
            
            return (amountPerSlice.mul(NumberOfSlicesPassed), NumberOfSlicesPassed);
        }
    }

    function V_GetRemaingTime() public view returns(uint remaingTime, uint sliceNum){
        
        uint256 currentTime = block.timestamp; 
        
        if(currentTime <= startTime){
            //uint256 perSliceTime = timePeriodInSeconds.div(vestingSchedule.numberOfSlices);
            remaingTime = startTime.sub(currentTime);
            sliceNum = 0; 
        }
        else{
            
            if(currentTime >= endTime){
                
                remaingTime=0; sliceNum = noOfSlices;
            }
            else{

                uint256 timePassed = currentTime.sub(startTime);
                
                uint256 NumberOfSlicesPassed = timePassed.div(sliceTime);
                
                uint256 perSliceTime = (endTime - startTime).div(noOfSlices);
                
                uint256 remainTime = ((NumberOfSlicesPassed+1).mul(perSliceTime)).sub((timePassed));
                
                remaingTime=remainTime; sliceNum = NumberOfSlicesPassed;
            }
        }
    }

    function getTokenBalance(address _tokenAddress) public view returns(uint256 _tokenAmount){
        _tokenAmount = IERC20(_tokenAddress).balanceOf(address(this));
    }

    function emergencyWithdrawToken(address token, address destination) public onlyOwner returns (bool sent){
        IERC20(token).transfer(destination, IERC20(token).balanceOf(address(this)));
        return true;
    }

    function emergencyWithdrawCurrency(address destination) public onlyOwner returns (bool sent) {
        require(address(this).balance != 0, "ZERO_BALANCE");
        payable(destination).transfer(address(this).balance);
        return true;
    }

    function setOGBToken(address _OGBAddress) public onlyOwner{
        OGBAddress = _OGBAddress;
    }


    receive() external payable {}

    fallback() external payable {}
}
