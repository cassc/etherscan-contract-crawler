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
        // @dev: nft token id
        uint256 tokenId;
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
        uint256 currentCapInBusd;
        bool valid;
        uint256 insId;
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
    mapping(uint256 => INSConfiguration) public availableIns;

    // @dev: Tressury fee - interger value - example: 5000 -> 5%
    uint256 public tressuryFee = 2500; // 5000 = 5%

    // @dev: dictionary with principants deposits - token_id -> deposits
    mapping(uint256 => INSDeposit[]) private deposits;

    // @dev: list of active tokenId INS
    uint256[] private createdInsIds;

    uint256[] private createdInsTokenIds;

    mapping(uint256 => bool) private alreadyCompletedIns;

    mapping(uint256 => INSConfiguration[]) private tokenIns;

    uint256 private currentInsId = 1;

    event Deposit(
        uint256 _tokenId,
        uint256 _ins_id,
        address _target,
        uint256 _amount,
        address _referrer
    );
    event BUSDGiveBack(uint256 insId, address _target, uint256 amount);
    event BUSDAddressUpdated(address _address);
    event TokenAddressUpdated(address _address);
    event TressuryAddressUpdated(address _address);
    event INSComplete(uint256 insId, uint256 _tokenId);
    event TressuryFeeUpdated(uint256 _fee);
    event INSCreated(
        uint256 insId,
        uint256 tokenId,
        uint256 minCap,
        uint256 maxCap,
        uint256 pricePerToken,
        uint256 startBlock,
        uint256 endBlock,
        bool multipleDeposits
    );

    constructor(
        address _tokenAddress,
        address _busdAddress,
        address _tressuryAddress
    ) {
        token = IERC1155(_tokenAddress);
        tokenAddress = _tokenAddress;
        busd = IERC20(_busdAddress);
        tressuryAddress = _tressuryAddress;
    }

    function create(
        uint256 tokenId,
        uint256 minCap,
        uint256 maxCap,
        uint256 pricePerToken,
        uint256 startBlock,
        uint256 endBlock,
        uint256 referralFee,
        bool multipleDeposits,
        bytes memory _data
    ) external nonReentrant returns (uint256) {
        require(tokenId > 0, "INS: tokenId must be greater than 0");
        require(pricePerToken > 0, "INS: pricePerToken must ge greater than 0");
        require(
            referralFee <= 10000,
            "INS: referralFee must be equal or less than 10000"
        );
        require(
            token.balanceOf(msg.sender, tokenId) != 0,
            "INS: Insufficient balance"
        );

        require(
            startBlock < endBlock,
            "INS: startBlock must be less than endBlock"
        );

        token.safeTransferFrom(
            msg.sender,
            address(this),
            tokenId,
            maxCap,
            _data
        );

        INSConfiguration memory configuration = INSConfiguration(
            tokenId,
            pricePerToken,
            startBlock,
            endBlock,
            minCap,
            maxCap,
            maxCap * pricePerToken,
            minCap * pricePerToken,
            referralFee,
            multipleDeposits,
            msg.sender,
            0,
            true,
            currentInsId
        );
        availableIns[currentInsId] = configuration;

        createdInsIds.push(currentInsId);

        bool tokenIdAlreadyexists = false;
        for (uint256 i = 0; i < createdInsTokenIds.length; ++i) {
            if (createdInsTokenIds[i] == tokenId) {
                tokenIdAlreadyexists = true;
            }
        }

        if (!tokenIdAlreadyexists) {
            createdInsTokenIds.push(tokenId);
        }

        tokenIns[tokenId].push(configuration);

        emit INSCreated(
            currentInsId,
            tokenId,
            minCap,
            maxCap,
            pricePerToken,
            startBlock,
            endBlock,
            multipleDeposits
        );

        currentInsId++;

        return currentInsId - 1;
    }

    function deposit(
        uint256 insId,
        uint256 amount,
        address _referrer
    ) external nonReentrant {
        INSConfiguration storage configuration = availableIns[insId];
        require(configuration.valid, "INS: tokenId configuration not found");

        require(
            amount.mod(configuration.pricePerToken) == uint256(0),
            "amount can't be greater than minimal configured by INS"
        );

        if (configuration.maxCapInBusd != 0) {
            if (configuration.currentCapInBusd == configuration.maxCapInBusd) {
                revert("INS: Cap full.");
            }

            uint256 availableCap = configuration.maxCapInBusd -
                configuration.currentCapInBusd;
            if (amount > availableCap) {
                revert("INS: amount exceeds available cap.");
            }
        }

        require(block.number >= configuration.startBlock, "INS not started");
        require(block.number <= configuration.endBlock, "INS ended");

        INSDeposit memory walletDeposit = INSDeposit(
            msg.sender,
            amount,
            _referrer
        );

        uint256 currentCapInBusd = configuration.currentCapInBusd + amount;

        if (configuration.multipleDeposits) {
            busd.transferFrom(msg.sender, address(this), amount);
            deposits[insId].push(walletDeposit);

            configuration.currentCapInBusd = currentCapInBusd;
        } else {
            INSDeposit[] memory insDeposits = deposits[insId];
            bool deposited = false;
            for (uint256 i = 0; i < insDeposits.length; ++i) {
                if (insDeposits[i].wallet == msg.sender) {
                    deposited = true;
                }
            }

            if (deposited) {
                revert("INS: doesn't support multiple deposits");
            } else {
                busd.transferFrom(msg.sender, address(this), amount);
                deposits[insId].push(walletDeposit);
                configuration.currentCapInBusd = currentCapInBusd;
            }
        }

        availableIns[insId] = configuration;

        emit Deposit(
            configuration.tokenId,
            insId,
            msg.sender,
            amount,
            _referrer
        );
    }

    function withdraw(uint256 insId, bytes memory _data) external nonReentrant {
        require(
            availableIns[insId].valid,
            "INS: insId configuration not found"
        );
        INSConfiguration storage configuration = availableIns[insId];
        INSConfiguration[] memory tokenConfiguration = tokenIns[
            configuration.tokenId
        ];

        bool canWidtraw = false;
        if (configuration.operator == msg.sender) {
            canWidtraw = true;
        } else {
            for (uint256 i = 0; i < deposits[insId].length; i++) {
                INSDeposit memory currentDeposit = deposits[insId][i];
                if (currentDeposit.wallet == msg.sender) {
                    canWidtraw = true;
                }
            }
        }

        if (!canWidtraw) {
            revert(
                "INS: You must be operator of the token or one of user that deposited funds."
            );
        }

        require(block.number >= configuration.endBlock, "INS: not ended");

        require(alreadyCompletedIns[insId] != true);

        uint256 tokenTransfered = 0;

        if (configuration.minCap != 0) {
            if (configuration.currentCapInBusd < configuration.minCapInBusd) {
                for (uint256 i = 0; i < deposits[insId].length; i++) {
                    busd.transfer(
                        deposits[insId][i].wallet,
                        deposits[insId][i].amount
                    );
                    emit BUSDGiveBack(
                        insId,
                        deposits[insId][i].wallet,
                        deposits[insId][i].amount
                    );
                }
            } else {
                tokenTransfered = processWithdraw(
                    configuration,
                    configuration.operator,
                    deposits[insId],
                    _data
                );
            }
        } else {
            tokenTransfered = processWithdraw(
                configuration,
                configuration.operator,
                deposits[insId],
                _data
            );
        }

        uint256 tokenBalance = configuration.maxCap - tokenTransfered;

        if (tokenBalance != 0) {
            token.safeTransferFrom(
                address(this),
                configuration.operator,
                configuration.tokenId,
                tokenBalance,
                _data
            );
        }

        for (uint256 i = 0; i < tokenConfiguration.length; i++) {
            if (tokenConfiguration[i].insId == configuration.insId) {
                delete tokenConfiguration[i];
                delete tokenIns[configuration.tokenId][i];
            }
        }

        bool allInsForTokenIdFinalized = true;

        for (uint256 i = 0; i < tokenConfiguration.length; i++) {
            if (tokenConfiguration[i].valid) {
                allInsForTokenIdFinalized = false;
            }
        }

        if (allInsForTokenIdFinalized) {
            for (uint256 i = 0; i < createdInsTokenIds.length; i++) {
                if (createdInsTokenIds[i] == configuration.tokenId) {
                    delete createdInsTokenIds[i];
                }
            }
        }

        configuration.valid = false;
        alreadyCompletedIns[insId] = true;
        emit INSComplete(insId, configuration.tokenId);
    }

    function walletDeposits(uint256 insId)
        public
        view
        returns (INSDeposit[] memory)
    {
        return deposits[insId];
    }

    function getCreatedInsTokenIds() public view returns (uint256[] memory) {
        return createdInsTokenIds;
    }

    function getCreatedInsIds() public view returns (uint256[] memory) {
        return createdInsIds;
    }

    function getTokenIns(uint256 tokenId)
        public
        view
        returns (INSConfiguration[] memory)
    {
        return tokenIns[tokenId];
    }

    function getAllAvailableIns()
        public
        view
        returns (INSConfiguration[] memory)
    {
        INSConfiguration[] memory availableInsList = new INSConfiguration[](
            createdInsIds.length
        );
        for (uint256 i = 0; i < createdInsIds.length; i++) {
            availableInsList[i] = availableIns[createdInsIds[i]];
        }
        return availableInsList;
    }

    function setTokenAddress(address _newAddress) external onlyOwner {
        token = IERC1155(_newAddress);
        tokenAddress = _newAddress;
        emit TokenAddressUpdated(_newAddress);
    }

    function setTressuryFee(uint256 _fee) external onlyOwner {
        require(_fee < 2500, "INS: Fee can't be greater than 2,5%; 2500");
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

    function processWithdraw(
        INSConfiguration memory configuration,
        address operator,
        INSDeposit[] memory insWalletDeposits,
        bytes memory _data
    ) private returns (uint256) {
        if (insWalletDeposits.length == 0) {
            return 0;
        }

        uint256 tokenTransfered = 0;
        for (uint256 i = 0; i < insWalletDeposits.length; i++) {
            uint256 fee = (insWalletDeposits[i].amount.mul(tressuryFee)).div(
                100000
            );
            uint256 depositAmount = insWalletDeposits[i].amount - fee;

            if (insWalletDeposits[i].referrer != address(0)) {
                uint256 referrerFee = (
                    insWalletDeposits[i].amount.mul(configuration.referralFee)
                ).div(100000);
                if (referrerFee != 0) {
                    depositAmount = depositAmount - referrerFee;
                    busd.transfer(insWalletDeposits[i].referrer, referrerFee);
                }
            }

            uint256 tokenAmount = insWalletDeposits[i].amount.div(
                configuration.pricePerToken
            );

            busd.transfer(operator, depositAmount);
            busd.transfer(tressuryAddress, fee);
            token.safeTransferFrom(
                address(this),
                insWalletDeposits[i].wallet,
                configuration.tokenId,
                tokenAmount,
                _data
            );
            tokenTransfered += tokenAmount;
        }

        return tokenTransfered;
    }
}