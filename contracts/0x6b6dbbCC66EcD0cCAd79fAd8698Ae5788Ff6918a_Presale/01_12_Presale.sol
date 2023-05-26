// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// This contract uses ECDSA signatures for CREE Presale
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

error IncorrectSignature();

/// @custom:security-contact [email protected]
// Contract for Launch Contributors, Version 1.0 
/*

https://creebank.org

_________________________________________ .__  _________   ________ ________   ________  ________   
\_   ___ \______   \_   _____/\_   _____/ |__|/   _____/  /  _____/ \_____  \  \_____  \ \______ \  
/    \  \/|       _/|    __)_  |    __)_  |  |\_____  \  /   \  ___  /   |   \  /   |   \ |    |  \ 
\     \___|    |   \|        \ |        \ |  |/        \ \    \_\  \/    |    \/    |    \|    `   \
 \______  /____|_  /_______  //_______  / |__/_______  /  \______  /\_______  /\_______  /_______  /
        \/       \/        \/         \/             \/          \/         \/         \/        \/ 

  606 bb CREE
0x6b6dbbCC66E
*/
contract Presale is ReentrancyGuard, Pausable, Ownable {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;
    
    // ECDSA signing address
    address private signingAddress;

    IERC20 public tokenForSale; // Specify token address in this format: IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 public usdtToken = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IERC20 public usdcToken = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    
    // hard cap for the sale
    uint256 public tokenAmountForSale = 10100000 * 10**18;

    // working. having to ratios for different token types makes it work better.
    uint256 public creePrice = 10**16; 
    uint256 public creePriceUSD = 0.01 * 10 ** 6; 


    bool public usersCanClaim = false;  // users can start to claim tokens from server
    bool public usersCanClaimAll  = false;  // users can claim ALL their contributions' worth of tokens


    uint256 public tokenAmountSold;

    uint256 public startingIndexBlock;  // keep the position right before first sale started.


    bool public directPurchaseIsActive = false;     // true (direct purchase of tokens enabled, no need to wait) | false (got to wait, escrow purchase until unlock)
    bool public bookingIsActive = false;     // true (you can purchase in escrow, need to wait for tokens unlock) | false (event is not active)


    struct ConversionRates {
        uint256 ethToUsd;
        uint256 usdtToUsd;
        uint256 usdcToUsd;
    }

    ConversionRates public conversionRates;

    struct Contribution {
        uint256 eth;
        uint256 usdt;
        uint256 usdc;
        uint256 creeTokens;
        uint256 attempts;
    }

    
    mapping(address => Contribution) public contributions;
    address[] private contributors;  // required to loop through contributions, as mapping does not store keys to allow looping


    


    constructor(address _aSignerAddress, address _presaleTokenAddress, address _usdtAddress, address _usdcAddress) {
        signingAddress = _aSignerAddress;
        tokenForSale = IERC20(_presaleTokenAddress);
        usdtToken = IERC20(_usdtAddress);
        usdcToken = IERC20(_usdcAddress);
    }

    function setConversionRates(
        uint256 _ethToUsd,
        uint256 _usdtToUsd,
        uint256 _usdcToUsd
    ) external onlyOwner {
        conversionRates.ethToUsd = _ethToUsd;
        conversionRates.usdtToUsd = _usdtToUsd;
        conversionRates.usdcToUsd = _usdcToUsd;
    }    


    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }


    function flipSaleBooking() external onlyOwner {
        bookingIsActive = !bookingIsActive;
    }


    function flipUsersCanClaim() external onlyOwner {
        usersCanClaim = !usersCanClaim;
    }    

    function flipUsersCanClaimAll() external onlyOwner {
        usersCanClaimAll = !usersCanClaimAll;
    }    


    function getContributors() external view onlyOwner returns (address[] memory) {
        return contributors;
    }

    function getContributorsCount() external view onlyOwner returns (uint256) {
        return contributors.length;
    }


    function userClaimTokens(bytes calldata signature, uint256 _currentBalance, uint256 _tokenAmountToGet) external nonReentrant whenNotPaused {
        require(usersCanClaim, "Claims not allowed yet");
        require(contributions[msg.sender].creeTokens > 0, "No tokens to withdraw");
        require(contributions[msg.sender].creeTokens == _currentBalance, "Already claimed");
        require(tokenForSale.balanceOf(address(this)) >= _tokenAmountToGet, "Not enough tokens in contract for claim. Try later.");

        if(!verifySignatureForClaims(msg.sender, _currentBalance, _tokenAmountToGet, signature)) revert IncorrectSignature();

        contributions[msg.sender].creeTokens -= _tokenAmountToGet;

        tokenForSale.safeTransfer(msg.sender, _tokenAmountToGet);
    }

    // set to internal when test is working.
    function verifySignatureForClaims(address sender, uint256 _currentBalance, uint256 _tokenAmountToGet, bytes memory signature) internal view returns(bool) {        
        string memory dataString = ''; 

        dataString = string(abi.encodePacked(dataString,Strings.toString(_currentBalance),Strings.toString(_tokenAmountToGet)));

        dataString = string(abi.encodePacked(dataString,Strings.toHexString(uint256(uint160(sender)), 20)));

        string memory message = dataString;

        bytes32 messageHash = keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n",
                    Strings.toString(bytes(message).length),
                    message
                )
            );
        
        // verifies if the signature signer is the same as our signing address.
        return signingAddress == ECDSA.recover(
            messageHash,
            signature
        );
    }                


    function userClaimAllTokens() external nonReentrant whenNotPaused {
        require(usersCanClaimAll, "Full claims not allowed yet");
        require(contributions[msg.sender].creeTokens > 0, "No tokens to withdraw");
        require(tokenForSale.balanceOf(address(this)) >= contributions[msg.sender].creeTokens, "Not enough tokens in contract for claim. Try later.");

        uint256 creeTokensToWithdraw = contributions[msg.sender].creeTokens;
        contributions[msg.sender].creeTokens = 0;

        tokenForSale.safeTransfer(msg.sender, creeTokensToWithdraw);
    }    


    function tokensInContract() external view onlyOwner returns(uint) {
        return tokenForSale.balanceOf(address(this));
    }

    function usdtInContract() external view onlyOwner returns(uint) {
        return usdtToken.balanceOf(address(this));
    }

    function usdcInContract() external view onlyOwner returns(uint) {
        return usdcToken.balanceOf(address(this));
    }


    
    function setSaleTokenAddress(address _presaleTokenAddress) external onlyOwner {
        tokenForSale = IERC20(_presaleTokenAddress);
    }

    function setUSDTAddress(address _usdtAddress) external onlyOwner {
        usdtToken = IERC20(_usdtAddress);
    }

    function setUSDCAddress(address _usdcAddress) external onlyOwner {
        usdcToken = IERC20(_usdcAddress);
    }



    // Sets the amount of token for sale in WEI format. 1000 tokens = 1000000000000000000000 in WEI.
    function setTokenAmountForSale(uint256 newAmount) external onlyOwner {
        tokenAmountForSale = newAmount;
    }

    function getTokenAmountLeftForSale() public view returns (uint) {
        return tokenAmountForSale - tokenAmountSold;
    }




    // when block.timestamp is between startTime and endTime, use the figures, if not, fallback to baseTokenRates.
    function contributeEth(bytes calldata signature, uint64 _startTime, uint64 _endTime, uint256 _ethToUsd, uint256 _tokenAmountToGet) external payable nonReentrant whenNotPaused {
        require(bookingIsActive, "Pre-sale not active!");
        require(getTokenAmountLeftForSale() > 0, "No more tokens left for sale");
        require(msg.value > 0, "Must send ETH to buy tokens");

        if(!verifySignatureForContributeEth(msg.sender, _startTime, _endTime, _ethToUsd, _tokenAmountToGet, signature)) revert IncorrectSignature();


        // protection against rate hack or sudden rate collapse, therefore rates cannot be better than known base rates.
        if (_ethToUsd > conversionRates.ethToUsd) {
            _ethToUsd = conversionRates.ethToUsd;
        }

        // call expired? rate no longer accurate, use base rate.
        /*
        if (block.timestamp >= _startTime && block.timestamp <= _endTime) {

        }
        else {
            _ethToUsd = conversionRates.ethToUsd;
        }
        */
        _ethToUsd = (block.timestamp >= _startTime && block.timestamp <= _endTime) ? _ethToUsd : conversionRates.ethToUsd;



        //require(block.timestamp <= presaleEndTime, "Presale ended");
        //uint256 contributionInUsd = msg.value * conversionRates.ethToUsd;
        uint256 contributionInUsd = msg.value * _ethToUsd;




        //require(contributions[msg.sender].eth + msg.value >= minEthContribution && contributions[msg.sender].eth + msg.value <= maxEthContribution, "Invalid contribution range");
        uint256 creeTokensPurchased = contributionInUsd / creePrice;

        // protection against token count hack, therefore choose to protect the token and contract, by using the lesser count.
        if (creeTokensPurchased > _tokenAmountToGet) {
            creeTokensPurchased = _tokenAmountToGet;
        }


        //require(getTokenAmountLeftForSale() >= creeTokensPurchased, "Not enough CREE tokens left");
        

        // if you happen to get more than what is left, you get them all.
        if (creeTokensPurchased > getTokenAmountLeftForSale()) {
            creeTokensPurchased = getTokenAmountLeftForSale();
        }

        if (startingIndexBlock == 0) {
            startingIndexBlock = block.number;
        }     

        // Check if the contributor is new (no attempts before), add to contributors list.
        if (contributions[msg.sender].attempts == 0) {
            contributors.push(msg.sender);
        }
        contributions[msg.sender].attempts += 1;


        contributions[msg.sender].eth += msg.value;
        contributions[msg.sender].creeTokens += creeTokensPurchased;
        tokenAmountSold += creeTokensPurchased;
    }

    function verifySignatureForContributeEth(address sender, uint64 _startTime, uint64 _endTime, uint256 _ethToUsd, uint256 _tokenAmountToGet, bytes memory signature) internal view returns(bool) {
        string memory dataString = '';
 
        dataString = string(abi.encodePacked(dataString,Strings.toString(_startTime),Strings.toString(_endTime)));

        // these data cannot match because of the way the are converted to string, so we need to send WEI value strings from server API all the way here.
        dataString = string(abi.encodePacked(dataString,Strings.toString(_ethToUsd),Strings.toString(_tokenAmountToGet)));
        
        dataString = string(abi.encodePacked(dataString,Strings.toHexString(uint256(uint160(sender)), 20)));

        string memory message = dataString;

        bytes32 messageHash = keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n",
                    Strings.toString(bytes(message).length),
                    message
                )
            );
        
        // verifies if the signature signer is the same as our signing address.
        return signingAddress == ECDSA.recover(
            messageHash,
            signature
        );
    }                   



    function contributeUsdt(uint256 _amount) external nonReentrant whenNotPaused {
        require(bookingIsActive, "Pre-sale not active!");
        require(_amount > 0, "Contribution amount must be greater than 0");
        require(usdtToken.allowance(msg.sender, address(this)) >= _amount, "Not enough allowance to transfer tokens");
        require(getTokenAmountLeftForSale() > 0, "No more tokens left for sale");

        //require(block.timestamp <= presaleEndTime, "Presale ended");
        uint256 contributionInUsd = _amount * conversionRates.usdtToUsd;
        //require(contributions[msg.sender].usdt + _amount >= minUsdtContribution && contributions[msg.sender].usdt + _amount <= maxUsdtContribution, "Invalid contribution range");
        uint256 creeTokensPurchased = contributionInUsd / creePriceUSD;

        //require(getTokenAmountLeftForSale() >= creeTokensPurchased, "Not enough CREE tokens left");


        // if you happen to get more than what is left, you get them all.
        if (creeTokensPurchased > getTokenAmountLeftForSale()) {
            creeTokensPurchased = getTokenAmountLeftForSale();
        }

        if (startingIndexBlock == 0) {
            startingIndexBlock = block.number;
        }


        // Check if the contributor is new (no attempts before), add to contributors list.
        if (contributions[msg.sender].attempts == 0) {
            contributors.push(msg.sender);
        }
        contributions[msg.sender].attempts += 1;


        contributions[msg.sender].usdt += _amount;
        contributions[msg.sender].creeTokens += creeTokensPurchased;
        tokenAmountSold += creeTokensPurchased;

        usdtToken.safeTransferFrom(msg.sender, address(this), _amount);
    }


    function contributeUsdc(uint256 _amount) external nonReentrant whenNotPaused {
        require(bookingIsActive, "Pre-sale not active!");
        require(_amount > 0, "Contribution amount must be greater than 0");
        require(usdcToken.allowance(msg.sender, address(this)) >= _amount, "Not enough allowance to transfer tokens");
        require(getTokenAmountLeftForSale() > 0, "No more tokens left for sale");

        //require(block.timestamp <= presaleEndTime, "Presale ended");
        uint256 contributionInUsd = _amount * conversionRates.usdcToUsd;
        //require(contributions[msg.sender].usdc + _amount >= minUsdtContribution && contributions[msg.sender].usdc + _amount <= maxUsdtContribution, "Invalid contribution range");
        uint256 creeTokensPurchased = contributionInUsd / creePriceUSD;

        //require(getTokenAmountLeftForSale() >= creeTokensPurchased, "Not enough CREE tokens left");


        // if you happen to get more than what is left, you get them all.
        if (creeTokensPurchased > getTokenAmountLeftForSale()) {
            creeTokensPurchased = getTokenAmountLeftForSale();
        }

        if (startingIndexBlock == 0) {
            startingIndexBlock = block.number;
        }     

        // Check if the contributor is new (no attempts before), add to contributors list.
        if (contributions[msg.sender].attempts == 0) {
            contributors.push(msg.sender);
        }
        contributions[msg.sender].attempts += 1;        

        contributions[msg.sender].usdc += _amount;
        contributions[msg.sender].creeTokens += creeTokensPurchased;
        tokenAmountSold += creeTokensPurchased;

        usdcToken.safeTransferFrom(msg.sender, address(this), _amount);
    }    


    // Once presale ends, and all tokens claimed, this contract can self-destruct to protect ecosystem and all participants
    // USDT transfer is clunky, so only self-destruct when all tokens are claimed.
    function selfDestruct(address payable _to) external onlyOwner {
        require(_to != address(0), "Invalid address");

        require(tokenForSale.balanceOf(address(this)) == 0, "There are still sale tokens in the contract!");
        require(address(this).balance == 0, "There are still ETH in the contract!");
        require(usdtToken.balanceOf(address(this)) == 0, "There are still USDT in the contract!");
        require(usdcToken.balanceOf(address(this)) == 0, "There are still USDC in the contract!");

        // Transfer remaining tokens back to the admin or a specified address
        uint256 remainingCreeTokens = tokenForSale.balanceOf(address(this));
        if (remainingCreeTokens > 0) {
            tokenForSale.safeTransfer(_to, remainingCreeTokens);
        }

        // Transfer remaining ETH back to the admin or a specified address
        uint256 remainingEth = address(this).balance;
        if (remainingEth > 0) {
            _to.transfer(remainingEth);
        }

        // Destroy the contract
        selfdestruct(_to);
    }    





     /**
     * @dev To decrypt ECDSA signatures
     */
    function setSigningAddress(address newSigningAddress) external onlyOwner {
        signingAddress = newSigningAddress;
    }

    // Owner-only function to get the list of contributors
    function getSigningAddress() external view onlyOwner returns (address) {
        return signingAddress;
    }    


    // for reserve and credit card orders, credit card orders require more checks, processing and local rules.
    function reserveOrderTokens(address recipient, uint256 _amountUSD) external onlyOwner {

        require(_amountUSD > 0, "Contribution amount must be greater than 0");

        require(getTokenAmountLeftForSale() > 0, "No more tokens left for sale");

        //require(block.timestamp <= presaleEndTime, "Presale ended");
        uint256 contributionInUsd = _amountUSD * conversionRates.usdtToUsd;
        uint256 creeTokensPurchased = contributionInUsd / creePriceUSD;

        //require(getTokenAmountLeftForSale() >= creeTokensPurchased, "Not enough CREE tokens left");


        // if you happen to get more than what is left, you get them all.
        if (creeTokensPurchased > getTokenAmountLeftForSale()) {
            creeTokensPurchased = getTokenAmountLeftForSale();
        }

        if (startingIndexBlock == 0) {
            startingIndexBlock = block.number;
        }

        // Check if the contributor is new (no attempts before), add to contributors list.
        if (contributions[recipient].attempts == 0) {
            contributors.push(recipient);
        }
        contributions[recipient].attempts += 1;        


        contributions[recipient].usdt += _amountUSD;  // we use usdt in general.
        contributions[recipient].creeTokens += creeTokensPurchased;
        tokenAmountSold += creeTokensPurchased;        

    }


    function setTokenUSDPrice(uint256 _priceInWei, uint256 _priceInSixDecimals) external onlyOwner {
        creePrice = _priceInWei; // 0.01 USD in wei, for ETH        
        creePriceUSD = _priceInSixDecimals; // 0.01 USD in for USDT/USDC
    }


    // Requires to use safeTransfer, because Tether's transfer is non-standard.
    function withdrawAllUSDT() external onlyOwner {
        uint256 usdtBalance = usdtToken.balanceOf(address(this));
        usdtToken.safeTransfer(msg.sender, usdtBalance);
    }

    function withdrawSomeUSDT(uint256 amount) external onlyOwner {
        require(usdtToken.balanceOf(address(this)) >= amount, "Not enough tokens available to withdraw");
        usdtToken.safeTransfer(msg.sender, amount);
    }


    function withdrawAllUSDC() external onlyOwner {
        uint256 usdcBalance = usdcToken.balanceOf(address(this));
        usdcToken.safeTransfer(msg.sender, usdcBalance);
    }


    function withdrawSomeUSDC(uint256 amount) external onlyOwner {
        require(usdcToken.balanceOf(address(this)) >= amount, "Not enough tokens available to withdraw");
        usdcToken.safeTransfer(msg.sender, amount);
    }    


    function withdrawSomeEth(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Not enough ETH available to withdraw");
        payable(msg.sender).transfer(amount);
    }        




    // SECURITY and PROTECTION of funds transferred.
    // These functions allows the contract to receive Ether, withdraw and send tokens, so investments and capital will not be locked or lost forever.
    // Situations include users who directly send Ether to the Sale contract.
    // A payable receive() function to enable the contract to receive Ether
    receive() external payable {
        // You can include any logic you want to be executed when the contract receives Ether
    }

    // A payable fallback() function to handle unmatched function calls
    fallback() external payable {
        // Logic to be executed when the contract receives Ether with unmatched function signature
    }        

    function withdrawTokensInContract(uint256 amount) external onlyOwner {
        require(tokenForSale.balanceOf(address(this)) >= amount, "Not enough tokens available to withdraw");
        tokenForSale.safeTransfer(msg.sender, amount);
    }

    function withdrawEth() external onlyOwner {
        require(address(this).balance > 0, "No ETH available to withdraw");
        payable(msg.sender).transfer(address(this).balance);
    }    

}