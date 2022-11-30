//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MetaproINS is Ownable, ERC1155Holder, ReentrancyGuard {
    using SafeMath for uint256;

    struct INSConfiguration {
        // @dev: price per 1 nft token - value in busd
        uint256 pricePerToken;

        // @dev: INS starting block
        uint256 startBlock;

        // @dev: INS ending block
        uint256 endBlock;

        // @dev: INS min token deposits - value in NFT token
        uint256 minCap;

        // @dev: INS max token deposits - value in NFT token
        uint256 maxCap;

        // @dev: INS max token deposits - value in BUSD
        uint256 maxCapInBusd;

        // @dev: INS min token deposits - value in BUSD
        uint256 minCapInBusd;

        // @dev: Referral fee - integer value - example: 5000 -> 5%
        uint256 referralFee;

        // @dev: Allow principants to do multiple deposits per INS
        bool multipleDeposits;

        // @dev: INS creator
        address operator;

        // @dev: Current capacity in BUSD
        uint currentCapInBusd;

        bool valid;
    }

    struct INSDeposit {
        // @dev: principal wallet address
        address wallet;

        // @dev: deposit amount in busd
        uint256 amount;

        // @dev: referrer address - can be 0x000....
        address referrer;
    }

    IERC1155 public token;
    IERC20 public busd;
    address public tressuryAddress;

    address private tokenAddress;

    // @dev: Current created INS
    mapping (uint256 => INSConfiguration) public availableIns;

    // @dev: Tressury fee - interger value - example: 5000 -> 5%
    uint256 public tressuryFee = 5000; // 5000 = 5%

    // @dev: dictionary with principants deposits - token_id -> deposits
    mapping (uint256 => INSDeposit[]) private deposits;

    // @dev: list of active tokenId INS
    uint256[] public createdTokenIds;

    mapping (uint256 => bool) public alreadyCompletedTokenIds;

    event Deposit(uint256 _tokenId, address _target, uint256 _amount, address _referrer);
    event Withdraw(uint256 _tokenId, address _target, uint256 _amount);
    event BUSDGiveBack(address _target, uint256 amount);
    event BUSDAddressUpdated(address _address);
    event TokenAddressUpdated(address _address);
    event TressuryAddressUpdated(address _address);
    event INSComplete(uint256 _tokenId);
    event TressuryFeeUpdated(uint256 _fee);
    event INSCreated(uint256 tokenId, uint256 minCap, uint256 maxCap, uint256 pricePerToken, uint256 startBlock, uint256 endBlock, bool multipleDeposits);

    constructor(address _tokenAddress, address _busdAddress, address _tressuryAddress) {
        token = IERC1155(_tokenAddress);
        tokenAddress = _tokenAddress;
        busd = IERC20(_busdAddress);
        tressuryAddress = _tressuryAddress;
    }

    function create(uint256 tokenId, uint256 minCap, uint256 maxCap, uint256 pricePerToken, uint256 startBlock, uint256 endBlock, uint256 referralFee, bool multipleDeposits, bytes memory _data) external {
        require(tokenId > 0, "INS: tokenId must be greater than 0");
        require(pricePerToken > 0, "INS: pricePerToken must ge greater than 0");
        require(referralFee <= 10000, "INS: referralFee must be equal or less than 10000");
        require(token.balanceOf(msg.sender, tokenId) != 0, "INS: Insufficient balance");
        require(availableIns[tokenId].valid == false, "INS: Already started");
        require(startBlock < endBlock, "INS: startBlock must be less than endBlock");

        token.safeTransferFrom(msg.sender, address(this), tokenId, maxCap, _data);

        INSConfiguration memory configuration = INSConfiguration(pricePerToken, startBlock, endBlock, minCap, maxCap, maxCap * pricePerToken, minCap * pricePerToken, referralFee, multipleDeposits, msg.sender, 0, true);
        availableIns[tokenId] = configuration;
        createdTokenIds.push(tokenId);

        emit INSCreated(tokenId, minCap, maxCap, pricePerToken, startBlock, endBlock, multipleDeposits);
    }

    function deposit(uint256 tokenId, uint256 amount, address _referrer) external nonReentrant {
        require(availableIns[tokenId].valid, "INS: tokenId configuration not found");

        INSConfiguration storage configuration = availableIns[tokenId];

        require(amount.mod(configuration.pricePerToken) == uint256(0), "amount can't be greater than minimal configured by INS");

        if (configuration.maxCapInBusd != 0) {
            if (configuration.currentCapInBusd == configuration.maxCapInBusd) {
                revert("INS: Cap full.");
            }

            uint256 availableCap = configuration.maxCapInBusd - configuration.currentCapInBusd;
            if (amount > availableCap) {
                revert("INS: amount exceeds available cap.");
            }
        }

        require(block.number >= configuration.startBlock, "INS not started");
        require(block.number <= configuration.endBlock, "INS ended");

        INSDeposit memory walletDeposit = INSDeposit(msg.sender, amount, _referrer);

        if (configuration.multipleDeposits) {
            depositBusd(configuration, walletDeposit, tokenId, amount);
        } else {
            INSDeposit[] memory insDeposits = deposits[tokenId];
            bool deposited = false;
            for (uint256 i = 0; i < insDeposits.length; ++i) {
                if (insDeposits[i].wallet == msg.sender) {
                    deposited = true;
                }
            }

            if (deposited) {
                revert("INS: doesn't support multiple deposits");                
            } else {
                depositBusd(configuration, walletDeposit, tokenId, amount);
            }
        }

        emit Deposit(tokenId, msg.sender, amount, _referrer);
    }

    function withdraw(uint256 tokenId, bytes memory _data) external {
        require(availableIns[tokenId].valid, "INS: tokenId configuration not found");
        INSConfiguration storage configuration = availableIns[tokenId];

        require(configuration.operator == msg.sender, "INS: You must be operator of the token");

        require(block.number >= configuration.endBlock, "INS: not ended");

        require(alreadyCompletedTokenIds[tokenId] != true);

        if (configuration.minCap != 0) {
            if (configuration.currentCapInBusd < configuration.minCapInBusd) {
                for (uint256 i = 0; i < deposits[tokenId].length; i++) {
                    busd.transfer(deposits[tokenId][i].wallet, deposits[tokenId][i].amount);
                    emit BUSDGiveBack(deposits[tokenId][i].wallet, deposits[tokenId][i].amount);
                }
            } else {
                processWithdraw(configuration, tokenId, configuration.operator, deposits[tokenId], _data);
            }
        } else {
            processWithdraw(configuration, tokenId, configuration.operator, deposits[tokenId], _data);
        }

        uint256 tokenBalance = token.balanceOf(address(this), tokenId);
        if (tokenBalance != 0) {
            token.safeTransferFrom(address(this), configuration.operator, tokenId, tokenBalance, _data);
        } 

        // availableIns[tokenId] = INSConfiguration(0, 0, 0, 0, 0, 0, 0, 0, false, address(0), 0, false);
        
        // delete createdTokenIds[tokenId];

        // for (uint256 i = 0; i < deposits[tokenId].length; i++) { 
        //     delete deposits[tokenId][i];
        // }

        alreadyCompletedTokenIds[tokenId] = true;
        emit INSComplete(tokenId);
    }

    function walletDeposits(uint256 tokenId) public view returns (INSDeposit[] memory) {
        return deposits[tokenId];
    }

    function getCreatedTokenIds() public view returns (uint256[] memory) {
        return createdTokenIds;
    }

    function setTokenAddress(address _newAddress) external onlyOwner {
        token = IERC1155(_newAddress);
        tokenAddress = _newAddress;
        emit TokenAddressUpdated(_newAddress);
    }

    function setTressuryFee(uint256 _fee) external onlyOwner {
        tressuryFee = _fee;
        emit TressuryFeeUpdated(_fee);
    }

    function setBusdAddress(address _newAddress) external onlyOwner {
        busd = IERC20(_newAddress);
        emit BUSDAddressUpdated(_newAddress);
    }

    function setTressuryAddress(address _newAddress) external onlyOwner {
        tressuryAddress = _newAddress;
        emit TressuryAddressUpdated(_newAddress);
    }

    function depositBusd(INSConfiguration storage configuration, INSDeposit memory walletDeposit, uint256 tokenId, uint256 amount) private {
        busd.transferFrom(msg.sender, address(this), amount);
        deposits[tokenId].push(walletDeposit);
        configuration.currentCapInBusd = configuration.currentCapInBusd + amount;
    }

    function processWithdraw(INSConfiguration storage configuration, uint256 tokenId, address operator, INSDeposit[] memory insWalletDeposits, bytes memory _data) private {
        if (insWalletDeposits.length == 0) {
            return;
        }

        for (uint256 i = 0; i < insWalletDeposits.length; i++) {
            uint256 fee = (insWalletDeposits[i].amount.mul(tressuryFee)).div(100000);
            uint256 depositAmount = insWalletDeposits[i].amount - fee;

            if (insWalletDeposits[i].referrer != address(0)) {
                uint256 referrerFee = (insWalletDeposits[i].amount.mul(configuration.referralFee)).div(100000);
                depositAmount = depositAmount - referrerFee;
                busd.transfer(insWalletDeposits[i].referrer, referrerFee);
            }

            uint256 tokenAmount = insWalletDeposits[i].amount.div(configuration.pricePerToken);
                
            busd.transfer(operator, depositAmount);
            busd.transfer(tressuryAddress, fee);
            token.safeTransferFrom(address(this), insWalletDeposits[i].wallet, tokenId, tokenAmount, _data);
        }
    }
}