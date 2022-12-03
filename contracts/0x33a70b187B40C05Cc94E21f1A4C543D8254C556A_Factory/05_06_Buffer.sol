// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Buffer is Initializable, ReentrancyGuard {
    uint256 public totalReceived;
    uint256 private totalAmount;
    struct ShareData {
        uint256 shareAmount;
        uint256 lastBlockNumber;
        uint256 withdrawn;
    }

    address public curator;
    uint256 private totalOwnersFee;
    uint256 private totalCreatorsFee;
    uint256 private totalPartnersFee;
    uint256 public royaltyFee;

    mapping(address => ShareData) public _shareData;
    uint256 public totalShares;
    uint256 public totalSharesOfPartners;
    mapping(uint256 => address) private partnersGroup;
    uint256 private partnersGroupLength = 0;
    mapping(uint256 => address) private creatorsGroup;
    uint256 private creatorsGroupLength = 0;
    mapping(uint256 => uint256) private creatorPairInfo;
    mapping(uint256 => address) private ownersGroup;
    uint256 private ownersGroupLength = 0;

    //////////
    mapping(uint256 => uint256) public shareDetails;
    uint256 private shareDetailLength = 0;
    mapping(uint256 => uint256) public partnerShareDetails;
    address private deadAddress = 0x0000000000000000000000000000000000000000;
    uint256 private totalCntOfContent = 0;
    //////////

    address public marketWallet; // wallet address for market fee

    address public owner;
    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not the owner.");
        _;
    }

    event UpdateCreatorPairsCheck(bool updated);
    event UpdateCreatorsGroupCheck(bool updateGroup);
    event UpdateFeeCheck(uint256 feePercent);
    event WithdrawnCheck(address to, uint256 amount);
    event UpdateSharesCheck(uint256[] share, uint256[] partnerShare);

    function initialize(
        address _owner,
        address _curator, // address for curator
        address[] memory _partnersGroup, // array of address for partners group
        address[] memory _creatorsGroup, // array of address for creators group
        uint256[] calldata _shares, // array of share percentage for every group
        uint256[] calldata _partnerShare, // array of share percentage for every members of partners group
        address _marketWallet
    ) public payable initializer {
        curator = _curator;

        for (uint256 i = 0; i < _partnersGroup.length; i++) {
            for (uint256 j = 0; j < i; j++) {
                require(
                    partnersGroup[j] != _partnersGroup[i],
                    "Partner address is repeated, please check again."
                );
            }
            partnersGroup[i] = _partnersGroup[i];
            partnersGroupLength++;
        }
        for (uint256 i = 0; i < _creatorsGroup.length; i++) {
            for (uint256 j = 0; j < i; j++) {
                require(
                    creatorsGroup[j] != _creatorsGroup[i],
                    "Creator address is repeated, please check again."
                );
            }
            creatorsGroup[i] = _creatorsGroup[i];
            creatorsGroupLength++;
        }
        require(_shares.length == 7, "Please input shares info correctly.");
        for (uint256 i = 0; i < _shares.length - 1; i++) {
            //////////
            totalShares += _shares[i];
            shareDetails[i] = _shares[i];
            shareDetailLength++;
            //////////
        }
        require(totalShares > 0, "Sum of share percentages must be greater than 0.");
        require(
            _partnersGroup.length == _partnerShare.length,
            "Please input partner group shares information correctly."
        );
        for (uint256 i = 0; i < _partnerShare.length; i++) {
            totalSharesOfPartners += _partnerShare[i];
            //////////
            partnerShareDetails[i] = _partnerShare[i];
            //////////
        }
        marketWallet = _marketWallet;
        owner = _owner;
        royaltyFee = 10;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    receive() external payable {
        totalReceived += msg.value;
        totalAmount += msg.value;
    }

    // Get the last block number
    function getBlockNumber(address account) external view returns (uint256) {
        return _shareData[account].lastBlockNumber;
    }

    function updateFeePercent(uint256 _royaltyFee) public onlyOwner {
        require(
            _royaltyFee < 20,
            "Your royalty percentage is set as over 20%."
        );
        royaltyFee = _royaltyFee;
        emit UpdateFeeCheck(royaltyFee);
    }

    function updateCreatorsGroupMint(address[] calldata _creatorsGroup) external onlyOwner {
        uint256 tmp = totalCreatorsFee / _creatorsGroup.length;
        for (uint256 i = 0; i < _creatorsGroup.length; i++) {
            _shareData[_creatorsGroup[i]].shareAmount += tmp;
        }
        totalCreatorsFee = 0;
        emit UpdateCreatorsGroupCheck(true);
    }

    // update creator pair info of creators addresses and tokenIDs of same lengths
    function updateCreatorsGroup(address[] calldata _creatorsGroup, uint256[] calldata _numOfTokens) external onlyOwner {
        require(
            _creatorsGroup.length == _numOfTokens.length,
            "Please input the creators info and tokenIDs as same length."
        );

        creatorsGroupLength = _creatorsGroup.length;
        for (uint256 i = 0; i < creatorsGroupLength; i++) {
            totalCntOfContent += _numOfTokens[i];
            creatorPairInfo[i] = totalCntOfContent;
            creatorsGroup[i] = _creatorsGroup[i];
            _shareData[_creatorsGroup[i]].shareAmount += totalCreatorsFee / _creatorsGroup.length;
        }
        totalCreatorsFee = 0;
        emit UpdateCreatorsGroupCheck(true);
    }

    function updateOwners(address[] calldata _owners) external onlyOwner {
        require(totalOwnersFee > 0 && shareDetails[5] > 0, "No need to update now, please update the owners list later.");
        ownersGroupLength = _owners.length;
        uint256 tmp = totalOwnersFee / ownersGroupLength;
        for (uint256 i = 0; i < ownersGroupLength; i++) {
            ownersGroup[i] = _owners[i];
            _shareData[_owners[i]].shareAmount += tmp;
        }
        totalOwnersFee = 0;
    }

    function updateRoyaltyPercentage(uint256[] calldata _share, uint256[] calldata _partnerShare) external onlyOwner {
        require(_share.length == shareDetailLength + 1, "Please input share info correctly");
        require(_partnerShare.length == partnersGroupLength, "Please input partners share info correctly");

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

        require(totalTmp > 0, "Please input valid share info. Sum of them must be greater than 0.");
        totalShares = totalTmp;
        totalSharesOfPartners = partnersTmp;

        emit UpdateSharesCheck(_share, _partnerShare);
    }

    // Withdraw
    function withdraw(
        address account, // address to ask withdraw
        address[] calldata sellerAddresses, // array of sellers address
        uint256[] calldata tokenIDs, // array of tokenIDs to be sold
        uint256[] calldata prices // array of prices of NFTs to be sold
    ) external nonReentrant {
        _shareData[account].lastBlockNumber = block.number;
        uint256 index = 0;
        uint256 i = 0;
        for (i = 0; i < tokenIDs.length; i++) {
            for (index = 0; index < creatorsGroupLength; index++) {
                if (tokenIDs[i] < creatorPairInfo[index]) {
                    break;
                }
            }
            _shareData[creatorsGroup[index]].shareAmount += shareDetails[3] * prices[i] * royaltyFee / 100 / totalShares;
            if (sellerAddresses[i] != deadAddress) {
                _shareData[sellerAddresses[i]].shareAmount += shareDetails[4] * prices[i] * royaltyFee / 100 / totalShares;
            }
        }

        if (totalAmount > 0) {
            totalOwnersFee += (totalAmount * shareDetails[5]) / totalShares;
            _shareData[curator].shareAmount += (totalAmount * shareDetails[0]) / totalShares;
            totalPartnersFee += (totalAmount * shareDetails[1]) / totalShares;
            totalCreatorsFee += (totalAmount * shareDetails[2]) / totalShares;
            totalAmount = 0;
        }

        if (totalCreatorsFee > 0 && creatorsGroupLength > 0) {
            for (i = 0; i < creatorsGroupLength; i++) {
                _shareData[creatorsGroup[i]].shareAmount += totalCreatorsFee / creatorsGroupLength;
            }
            totalCreatorsFee = 0;
        }

        if (totalOwnersFee > 0 && ownersGroupLength > 0) {
            for (i = 0; i < ownersGroupLength; i++) {
                _shareData[ownersGroup[i]].shareAmount += totalOwnersFee / ownersGroupLength;
            }
            totalOwnersFee = 0;
        }

        if (totalPartnersFee > 0) {
            for (i = 0; i < partnersGroupLength; i++) {
                _shareData[partnersGroup[i]].shareAmount += totalPartnersFee * partnerShareDetails[i] / totalSharesOfPartners;
            }
            totalPartnersFee = 0;
        }
        
        if (_shareData[account].shareAmount > 0) {
            _transfer(account, _shareData[account].shareAmount);
            _shareData[account].withdrawn += _shareData[account].shareAmount;
            _shareData[account].shareAmount = 0;
        }
        emit WithdrawnCheck(account, _shareData[account].shareAmount);
    }

    // adopted from https://github.com/lexDAO/Kali/blob/main/contracts/libraries/SafeTransferLib.sol
    error TransferFailed();

    function _transfer(address to, uint256 amount) internal {
        bool callStatus;
        assembly {
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }
        if (!callStatus) revert TransferFailed();
    }
}