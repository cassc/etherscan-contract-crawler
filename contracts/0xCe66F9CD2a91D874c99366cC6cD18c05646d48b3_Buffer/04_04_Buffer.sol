// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Buffer is Initializable, ReentrancyGuard {
    struct ShareData {
        uint256 shareAmount;
        uint256 withdrawn;
    }

    uint256 public lastBlockNumber;
    uint256 public totalReceived;
    mapping(uint256 => uint256) private Fees;
    uint256 public royaltyFeePercent;

    mapping(address => ShareData) public _shareData;
    uint256 public totalShares;
    uint256 public totalSharesOfPartners;
    mapping(uint256 => address) private partnersGroup;
    uint256 private partnersGroupLength = 0;
    mapping(uint256 => address) private creatorsGroup;
    uint256 private creatorsGroupLength = 0;
    mapping(uint256 => address) private creatorsPairAddress;
    mapping(uint256 => uint256) private creatorsPairIndex;
    uint256 private creatorsPairLengh = 0;
    mapping(uint256 => address) private ownersGroup;
    uint256 private ownersGroupLength = 0;

    mapping(uint256 => uint256) public shareDetails;
    uint256 private shareDetailLength = 0;
    mapping(uint256 => uint256) public partnerShareDetails;
    uint256 private totalCntOfContent = 0;

    address public marketWallet; // wallet address for market fee
    address public owner;

    event UpdateCreatorPairsCheck(bool updated);
    event UpdateCreatorsGroupCheck(bool updateGroup);
    event UpdateFeeCheck(uint256 feePercent);
    event WithdrawnCheck(address to, uint256 amount);
    event UpdateSharesCheck(uint256[] share, uint256[] partnerShare);

    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not the owner.");
        _;
    }
    //============ Function to Receive ETH ============
    receive() external payable {
        totalReceived += msg.value;
        for (uint256 i = 0; i < 5; i++) {
            Fees[i] += msg.value * shareDetails[i] / totalShares;
        }
        _transfer(marketWallet, Fees[4]);
        Fees[4] = 0;
    }
    //============ Function to Transfer Ownership ============
    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }
    //============ Function to Update Creators Addresses ============
    function updateCreatorsGroup(address[] calldata _creatorsGroup) external onlyOwner {
        creatorsGroupLength = _creatorsGroup.length;
        uint256 tmp = Fees[2] / creatorsGroupLength;
        for (uint256 i = 0; i < creatorsGroupLength; i++) {
            _shareData[_creatorsGroup[i]].shareAmount += tmp;
            creatorsGroup[i] = _creatorsGroup[i];
        }
        Fees[2] = 0;
        emit UpdateCreatorsGroupCheck(true);
    }
    //============ Function to Update Pair of Creator:Tokens ============
    function updateCreatorsPairInfo(address[] calldata _creators, uint256[] calldata _numOfTokens) external onlyOwner {
        require(
            _creators.length == _numOfTokens.length,
            "Creators group info's lengths are different"
        );
        for (uint256 i = 0; i < _creators.length; i++) {
            totalCntOfContent += _numOfTokens[i];
            creatorsPairAddress[totalCntOfContent] = _creators[i];
            creatorsPairIndex[i] = totalCntOfContent;
        }
        creatorsPairLengh += _creators.length;
        emit UpdateCreatorsGroupCheck(true);
    }
    //============ Function to Update NFT Holders ============
    function updateOwners(address[] calldata _owners) external onlyOwner {
        require(shareDetails[3] > 0, "Please update the owners list later.");
        ownersGroupLength = _owners.length;
        uint256 tmp = Fees[3] / ownersGroupLength;
        for (uint256 i = 0; i < ownersGroupLength; i++) {
            ownersGroup[i] = _owners[i];
            _shareData[_owners[i]].shareAmount += tmp;
        }
        Fees[3] = 0;
    }
    //============ Function to Update Royalty Shares ============
    function updateRoyaltyShares(uint256[] calldata _share, uint256[] calldata _partnerShare) external onlyOwner {
        require(_share.length == shareDetailLength, "Shares info length is invalid");
        require(_partnerShare.length == partnersGroupLength, "Partners group lengths are different");

        uint256 totalTmp = 0;
        uint256 partnersTmp = 0;

        for (uint256 i =0; i < _share.length - 1; i++) {
            shareDetails[i] = _share[i];
            totalTmp += _share[i];
        }

        for (uint256 i = 0; i < _partnerShare.length; i++) {
            partnerShareDetails[i] = _partnerShare[i];
            partnersTmp += _partnerShare[i];
        }

        require(totalTmp > 0, "Sum of shares must be greater than 0");
        totalShares = totalTmp;
        totalSharesOfPartners = partnersTmp;

        emit UpdateSharesCheck(_share, _partnerShare);
    }
    //============ Function to Update NFT Sale info to Calculate Artist's Share ============
    function updateNFTSalesForArtistShare(
        uint256[] calldata tokenIDs, // array of tokenIDs sold
        uint256[] calldata prices // array of prices of NFTs sold
    ) external onlyOwner {
        require(tokenIDs.length == prices.length, "Please input valid info with same length");
        lastBlockNumber = block.number;
        uint256 index = 0;
        uint256 i = 0;
        
        if (Fees[0] > 0) {
            uint256 tmpArtistFee = 0;
            for (i = 0; i < tokenIDs.length; i++) {
                for (index = 0; index < creatorsPairLengh; index++) {
                    if (tokenIDs[i] <= creatorsPairIndex[index]) {
                        break;
                    }
                }
                tmpArtistFee += shareDetails[0] * prices[i] * royaltyFeePercent / 10000 / totalShares;
            }
            require(tmpArtistFee == Fees[0], "Calculation of artist fee is invalid");

            for (i = 0; i < tokenIDs.length; i++) {
                for (index = 0; index < creatorsPairLengh; index++) {
                    if (tokenIDs[i] < creatorsPairIndex[index]) {
                        break;
                    }
                }
                _shareData[creatorsPairAddress[creatorsPairIndex[index]]].shareAmount += shareDetails[0] * prices[i] * royaltyFeePercent / 10000 / totalShares;
            }
            Fees[0] = 0;
        }
    }
    //============ Function to Withdraw ETH ============
    function withdraw() external nonReentrant {
        address account = msg.sender;
        uint256 i = 0;

        if (Fees[1] > 0) {
            for (i = 0; i < partnersGroupLength; i++) {
                _shareData[partnersGroup[i]].shareAmount += Fees[1] * partnerShareDetails[i] / totalSharesOfPartners;
            }
            Fees[1] = 0;
        }

        if (Fees[2] > 0 && creatorsGroupLength > 0) {
            for (i = 0; i < creatorsGroupLength; i++) {
                _shareData[creatorsGroup[i]].shareAmount += Fees[2] / creatorsGroupLength;
            }
            Fees[2] = 0;
        }

        if (Fees[3] > 0 && ownersGroupLength > 0) {
            for (i = 0; i < ownersGroupLength; i++) {
                _shareData[ownersGroup[i]].shareAmount += Fees[3] / ownersGroupLength;
            }
            Fees[3] = 0;
        }

        if (_shareData[account].shareAmount > 0) {
            _transfer(account, _shareData[account].shareAmount);
            _shareData[account].withdrawn += _shareData[account].shareAmount;
            _shareData[account].shareAmount = 0;
        }
        emit WithdrawnCheck(account, _shareData[account].shareAmount);
    }
    //============ Function to Initialize Contract ============
    function initialize(
        address _owner,
        address[] memory _partnersGroup, // array of address for partners group
        address[] memory _creatorsGroup, // array of address for creators group
        uint256[] calldata _shares, // array of share percentage for every group
        uint256[] calldata _partnerShare, // array of share percentage for every members of partners group
        address _marketWallet
    ) public payable initializer {
        lastBlockNumber = block.number;
        partnersGroupLength = _partnersGroup.length;
        for (uint256 i = 0; i < partnersGroupLength; i++) {
            for (uint256 j = 0; j < i; j++) {
                require(
                    partnersGroup[j] != _partnersGroup[i],
                    "Partner address is repeated"
                );
            }
            partnersGroup[i] = _partnersGroup[i];
        }

        creatorsGroupLength = _creatorsGroup.length;
        for (uint256 i = 0; i < creatorsGroupLength; i++) {
            for (uint256 j = 0; j < i; j++) {
                require(
                    creatorsGroup[j] != _creatorsGroup[i],
                    "Creator address is repeated"
                );
            }
            creatorsGroup[i] = _creatorsGroup[i];
        }

        shareDetailLength = _shares.length;
        require(shareDetailLength == 5, "Shares info length is invalid");
        for (uint256 i = 0; i < shareDetailLength; i++) {
            totalShares += _shares[i];
            shareDetails[i] = _shares[i];
        }
        require(totalShares > 0, "Sum of shares must be greater than 0");

        require(
            partnersGroupLength == _partnerShare.length,
            "Partners group info's lengths are different"
        );
        for (uint256 i = 0; i < _partnerShare.length; i++) {
            totalSharesOfPartners += _partnerShare[i];
            partnerShareDetails[i] = _partnerShare[i];
        }

        marketWallet = _marketWallet;
        owner = _owner;
        royaltyFeePercent = 1000;
    }
    //============ Function to Update Royalty Fee Percentage ============
    function updateFeePercent(uint256 _royaltyFeePercent) public onlyOwner {
        require(
            _royaltyFeePercent <= 10000,
            "Your royalty percentage is set as over 100%."
        );
        royaltyFeePercent = _royaltyFeePercent;
        emit UpdateFeeCheck(royaltyFeePercent);
    }

    // adopted from https://github.com/lexDAO/Kali/blob/main/contracts/libraries/SafeTransferLib.sol
    error TransferFailed();
    //============ Function to Transfer ETH to Address ============
    function _transfer(address to, uint256 amount) internal {
        bool callStatus;
        assembly {
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }
        if (!callStatus) revert TransferFailed();
    }
}