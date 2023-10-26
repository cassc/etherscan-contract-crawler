// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract BuccaneerV3Crowdsale {
    using SafeMath for uint256;

    IERC20 private token;
    address private owner;
    uint256 private endTime;
    uint256 private raisedAmount = 0;
    uint256 private tokenPrice = 60;  // 60 tokens per ETH
    uint256 private goal = 282 ether;
    uint256 private maxLimit = 20 ether;
    uint256 private minLimit = 0.1 ether;
    uint256 private totalTokens = 17100000000000000000000;
    string private description = "Buccaneer V3 is an advanced on-chain privacy token that allows users to discreetly send BUCC tokens around privately. BUCC will be available approximately a month after the sale has concluded. IMPORTANT LEGAL NOTICE: This transaction is not available to residents, citizens, or green card holders of the United States of America or any of its territories or possessions, including Puerto Rico, the U.S. Virgin Islands, and Guam (collectively, 'US Persons'). The service offered in this transaction has not been registered under the United States Securities Act of 1933, as amended (the 'Securities Act'), or any state securities laws, and may not be offered, sold, pledged, or otherwise transferred within the United States or to or for the benefit of US Persons, except pursuant to an exemption from, or in a transaction not subject to, the registration requirements of the Securities Act and applicable state securities laws. US Persons are not permitted to participate in the transaction offered here. By participating in this transaction, you represent and warrant that you are not a US Person and that you are not purchasing on behalf of or for the benefit of a US Person. The Buccaneer team does not accept any responsibility or liability for any violation of local regulations by any user. All participants must ensure they are compliant with their local regulations and laws before participating. The user assumes all responsibility and risk associated with this transaction, and the Buccaneer team will not be held liable for any actions, claims, damages, costs, or liabilities arising from or related to this contract. It's imperative that participants conduct thorough research and consult with legal professionals where necessary. By interacting with this contract, you agree to these terms.";
    //remember to fix
    bool private saleStarted = false;
    uint256 private tokensSold = 0;
    uint256 private startTime;


    struct Buyer {
        address buyerAddress;
        uint256 amountBought;
    }

    Buyer[] private buyers;
    mapping(address => uint256) private buyerIDs;
    mapping(address => uint256) private balances;
    mapping(address => bool) private userLock;
    mapping(address => uint256) private contributedEth;


    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    modifier hasMinimumPurchase() {
        require(msg.value >= minLimit, "0.1 ETH is the minimum purchase limit");
        _;
    }

    modifier hasMaximumPurchase() {
        require(contributedEth[msg.sender].add(msg.value) <= maxLimit, "20 ETH is the maximum total contribution per address");
        _;
    }

    modifier saleHasStarted() {
        require(saleStarted, "Sale has not started yet");
        _;
    }

    constructor() {
        owner = msg.sender;
        endTime = block.timestamp + 48 hours;
    }


    function VIII_startSale() external onlyOwner {
        startTime = block.timestamp;
        endTime = block.timestamp + 48 hours;
        saleStarted = true;
    }


    function VIII_setToken(address _token) external onlyOwner {
        //require(address(token) == address(0), "Token already set!");
        token = IERC20(_token);
    }


    function buyTokensInternal() internal hasMinimumPurchase hasMaximumPurchase saleHasStarted {
        require(!userLock[msg.sender], "Reentrant call detected!");

        userLock[msg.sender] = true;

        require(block.timestamp < endTime, "Sale ended");
        uint256 tokensToBuy = msg.value.mul(tokenPrice);

        // Calculate the number of tokens left for sale
        uint256 tokensLeft = totalTokens.sub(tokensSold);
        require(tokensLeft >= tokensToBuy, "Not enough tokens left to buy");

        // Assign ID if the buyer is new
        if(buyerIDs[msg.sender] == 0) {
            buyers.push(Buyer({
                buyerAddress: msg.sender,
                amountBought: tokensToBuy
            }));
            buyerIDs[msg.sender] = buyers.length;  // This will be the ID for the buyer
        } else {
            uint256 index = buyerIDs[msg.sender] - 1;
            buyers[index].amountBought = buyers[index].amountBought.add(tokensToBuy);
        }

        tokensSold = tokensSold.add(tokensToBuy);
        raisedAmount = raisedAmount.add(msg.value);
        balances[msg.sender] = balances[msg.sender].add(tokensToBuy);
        
        // Update the total ETH contributed by the sender
        contributedEth[msg.sender] = contributedEth[msg.sender].add(msg.value);

        userLock[msg.sender] = false;
    }

    function buyTokens() external payable hasMinimumPurchase hasMaximumPurchase saleHasStarted {
        buyTokensInternal();
    }

    receive() external payable {
        buyTokensInternal();
    }

    function claimTokens() external saleHasStarted {
        require(block.timestamp > endTime, "Sale not ended");
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No tokens to claim");
        require(token.transfer(msg.sender, amount), "Token transfer failed");
        balances[msg.sender] = 0;
    }

    function VIII_endSalePrematurely() external onlyOwner {
        require(saleStarted, "Sale hasn't started yet");
        require(block.timestamp < endTime, "Sale has already ended");
        endTime = block.timestamp;  // Set endTime to the current time to end the sale
    }

    function VIII_withdrawETH() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function VIII_emergencyPull(uint256 _amount) external onlyOwner {
        payable(owner).transfer(_amount);
    }


    function VIII_setTokenPrice(uint256 _price) external onlyOwner {
        tokenPrice = _price;
    }

    function VIII_setGoal(uint256 _goal) external onlyOwner {
        goal = _goal;
    }

                    
                    function A_Check_My_Balance() external view returns (string memory) {
                        address user = msg.sender;
                        uint256 userTokens = balances[user];
                        if (userTokens == 0) {
                            return "You haven't sent any tokens.";
                        }

                        uint256 percentageOfTotal = (userTokens.mul(100)).div(totalTokens);
                        string memory rank = getRank(contributedEth[user]);

                        string memory baseString = "You are ranked as a ";
                        string memory rankStr = rank;
                        string memory claimString = ". You will be able to claim ";
                        string memory tokensStr = _uintToString(userTokens.div(1e18)); // Displaying compact value
                        string memory middleString = " tokens, which is ";
                        string memory percentageStr = _uintToString(percentageOfTotal);
                        string memory endString = "% of the total tokens.";

                        bytes memory b = new bytes(400); // estimation of space required, increased due to the addition of rank

                        uint pos = 0;
                        for (uint i = 0; i < bytes(baseString).length; i++) b[pos++] = bytes(baseString)[i];
                        for (uint i = 0; i < bytes(rankStr).length; i++) b[pos++] = bytes(rankStr)[i];
                        for (uint i = 0; i < bytes(claimString).length; i++) b[pos++] = bytes(claimString)[i];
                        for (uint i = 0; i < bytes(tokensStr).length; i++) b[pos++] = bytes(tokensStr)[i];
                        for (uint i = 0; i < bytes(middleString).length; i++) b[pos++] = bytes(middleString)[i];
                        for (uint i = 0; i < bytes(percentageStr).length; i++) b[pos++] = bytes(percentageStr)[i];
                        for (uint i = 0; i < bytes(endString).length; i++) b[pos++] = bytes(endString)[i];

                        string memory finalStr = new string(pos);
                        for (uint i = 0; i < pos; i++) {
                            bytes(finalStr)[i] = b[i];
                        }

                        return finalStr;
                    }





                    function B_Show_What_Percentage_Sale_Is_Done() external view returns (string memory) {
                        if (block.timestamp > endTime) {
                            return "The sale is over.";
                        }

                        if (raisedAmount == 0) {
                            return "The sale hasn't had any ETH sent to it yet.";
                        }

                        uint256 percentage = raisedAmount.mul(100).div(goal);
                        return string(abi.encodePacked("The sale is at ", uint2str(percentage), " percentage towards completion."));
                    }




                    function C_getSaleStatus() external view returns (string memory) {

                        if (!saleStarted) {
                            return "The sale has not started.";
                        } else if (block.timestamp < endTime) {
                            uint256 timeRemaining = endTime.sub(block.timestamp);
                            uint256 U = timeRemaining.div(3600);
                            uint256 Z = (timeRemaining.sub(U.mul(3600))).div(60);
                            return string(abi.encodePacked("The sale is live, there are hours: ", _uintToString(U), " and ", _uintToString(Z), " minutes left."));

                        } else {
                            return "The Sale is Over";
                        }
                    }


                    function D_Tokens_Left_in_the_Sale() external view returns (string memory) {
                        if (block.timestamp > endTime) {
                            return "The sale is over.";
                        }

                        uint256 tokensRemaining = totalTokens.sub(tokensSold).div(1e18);
                        uint256 compactTokensSold = tokensSold.div(1e18);
                        
                        string memory tokensSoldStr = _uintToString(compactTokensSold);
                        string memory tokensRemainingStr = _uintToString(tokensRemaining);

                        // Constructing the status message
                        bytes memory b = new bytes(200); // estimation of space
                        string memory baseString = "A total of ";
                        string memory middleString = " tokens have been sold and ";
                        string memory endString = " are left.";

                        uint pos = 0;

                        for (uint i = 0; i < bytes(baseString).length; i++) b[pos++] = bytes(baseString)[i];
                        for (uint i = 0; i < bytes(tokensSoldStr).length; i++) b[pos++] = bytes(tokensSoldStr)[i];
                        for (uint i = 0; i < bytes(middleString).length; i++) b[pos++] = bytes(middleString)[i];
                        for (uint i = 0; i < bytes(tokensRemainingStr).length; i++) b[pos++] = bytes(tokensRemainingStr)[i];
                        for (uint i = 0; i < bytes(endString).length; i++) b[pos++] = bytes(endString)[i];

                        string memory finalStr = new string(pos);
                        for (uint i = 0; i < pos; i++) {
                            bytes(finalStr)[i] = b[i];
                        }

                        return finalStr;
                    }



                    function E_What_is_the_Minimum_Send_in_Limit() external pure returns (string memory) {
                        return "The minimum send limit is 0.1 Ethereum. The maximum input is 20 Ethereum per address.";
                    }

                    function F_What_is_the_Price() external view returns (string memory) {
                        return string(abi.encodePacked("The number of tokens per ETH is: ", uint2str(tokenPrice)));
                    }

                    function G_getBalanceByBuyerID(uint256 _buyerID) external view returns (string memory) {
                        // Ensure the buyerID is valid
                        require(_buyerID > 0 && _buyerID <= buyers.length, "Invalid buyerID");

                        // Retrieve the buyer's address using the buyerID
                        address buyerAddress = buyers[_buyerID - 1].buyerAddress;

                        // Convert the address to string
                        string memory addressStr = _addrToString(buyerAddress);

                        // Check if the user has a balance
                        uint256 balance = balances[buyerAddress];
                        if (balance == 0) {
                            return string(abi.encodePacked("Address: ", addressStr, " has not sent any ETH to the contract."));
                        } else {
                            return string(abi.encodePacked("Address: ", addressStr, " has a balance of: ", uint2str(balance)));
                        }
                    }


                    function H_getTotalBuyers() external view returns (string memory) {
                        if (block.timestamp > endTime) {
                            return string(abi.encodePacked("The sale is over. The final number of buyers was: ", uint2str(buyers.length)));
                        }
                        return string(abi.encodePacked("The total number of buyers is: ", uint2str(buyers.length)));
                    }



                    function I_getDescription() external view returns (string memory) {
                        return description;
                    }

                    int256 private virtualTimeOffset = 0;

                    function fastForwardTime(int256 fag) external onlyOwner {
                            virtualTimeOffset += fag;
                        }

                        // Helper function to get the current time (considering the offset)
                        function getCurrentTime() internal view returns (uint256) {
                            return block.timestamp + uint256(virtualTimeOffset);
                        }

                    function J_estimatedTimeToEndSale() external view saleHasStarted returns (string memory) {
                        if (block.timestamp >= endTime || tokensSold == totalTokens) {
                            return "The sale has either ended or all tokens are sold.";
                        }

                        uint256 averageRate = tokensSold.div(block.timestamp.sub(startTime)); // Tokens per second
                        if (averageRate == 0) {
                            return "Not enough data to estimate time to end sale.";
                        }

                        uint256 estimatedSecondsToEnd = totalTokens.sub(tokensSold).div(averageRate);
                        uint256 estimatedHoursToEnd = estimatedSecondsToEnd.div(3600);

                        return string(abi.encodePacked("Estimated hours to end sale: ", uint2str(estimatedHoursToEnd)));
                    }

                    function getRank(uint256 contribution) internal pure returns (string memory) {
                        if (contribution < 0.3 ether) return "Slave";
                        if (contribution < 1.5 ether) return "Swab";
                        if (contribution < 3 ether) return "Cook";
                        if (contribution < 4.5 ether) return "Boatswain";
                        if (contribution < 5 ether) return "Carpenter";
                        if (contribution < 7.5 ether) return "Chaplain";
                        if (contribution < 10 ether) return "Quartermaster";
                        if (contribution < 12.5 ether) return "Master Gunner";
                        if (contribution < 15 ether) return "Sailmaster";
                        return "First Mate";
                    }





                    //UTIL
                    function uint2str(uint256 _i) internal pure returns (string memory) {
                        if (_i == 0) {
                            return "0";
                        }
                        uint256 j = _i;
                        uint256 length;
                        while (j != 0) {
                            length++;
                            j /= 10;
                        }
                        bytes memory bstr = new bytes(length);
                        uint256 k = length;
                        while (_i != 0) {
                            bstr[--k] = bytes1(uint8(48 + _i % 10));
                            _i /= 10;
                        }
                        return string(bstr);
                    }



                    function _uintToString(uint256 _i) internal pure returns (string memory) {
                        if (_i == 0) {
                            return "0";
                        }
                        uint256 j = _i;
                        uint256 length;
                        while (j != 0) {
                            length++;
                            j /= 10;
                        }
                        bytes memory bstr = new bytes(length);
                        uint256 k = length;
                        j = _i;
                        while (j != 0) {
                            bstr[--k] = bytes1(uint8(48 + j % 10));
                            j /= 10;
                        }
                        return string(bstr);
                    }

                    function _addrToString(address _addr) internal pure returns(string memory) {
                        bytes32 value = bytes32(uint256(uint160(_addr)));
                        bytes memory alphabet = "0123456789abcdef";

                        bytes memory str = new bytes(42);
                        str[0] = '0';
                        str[1] = 'x';
                        for (uint256 i = 0; i < 20; i++) {
                            str[2+i*2] = alphabet[uint8(value[i + 12] >> 4)];
                            str[3+i*2] = alphabet[uint8(value[i + 12] & 0x0f)];
                        }
                        return string(str);
                    }

}