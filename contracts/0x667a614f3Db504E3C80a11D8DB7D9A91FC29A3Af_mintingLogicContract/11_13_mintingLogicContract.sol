//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Whitelist} from "./utils/WhiteListSigner.sol";
import {IPassengersMintingContract} from "./interface/IPassengersMintingContract.sol";

contract mintingLogicContract is OwnableUpgradeable, Whitelist {

    IPassengersMintingContract public mintingContract;


    error MintingLimitOver();
    error MasterListOver();
    error ReserveListOver();

    address public designatedSigner;
    bool public isPublicMinting;
    mapping (address => bool) public whitelistMintTransactionTracker;
    mapping (address => bool) public publicMintTransactionTracker;

    struct MasterList {
        uint256 masterListMintingLimit;
        uint256 reserveListMintingLimit;
        uint256 masterListMintingPrice;
        uint256 masterListMintingCount;
        uint256 masterListMintingTime;
        mapping (address => uint256) mintFromMasterList;
    }

    struct ReserveList {
        uint256 reserveListMintingLimit;
        uint256 reserveListMintingCount;
        uint256 reserveListMintingPrice;
        uint256 reserveListMintingTime;
        mapping (address => uint256) mintFromReserveList;
    }

    struct PublicMint {
        uint256 mintingLimit;
        uint256 mintingPrice;
        uint256 mintingCount;
        mapping (address => uint256) mintedPerUser;
    }

    MasterList public masterList;
    ReserveList public reserveList;
    PublicMint public publicMint;

    function setDesignatedSigner(address _signer) external onlyOwner {
        designatedSigner = _signer;
    }

    function initialize(address _designatedSigner) public initializer {
        __Ownable_init();
        __WhiteList_init();
        designatedSigner = _designatedSigner;

        //MasterList Setup
        masterList.masterListMintingLimit = 1;
        masterList.reserveListMintingLimit = 1;
        masterList.masterListMintingPrice = 0.1 ether;
        masterList.masterListMintingCount = 5000;
        masterList.masterListMintingTime = 1633046400; // to be changed

        //ReserveList Setup
        reserveList.reserveListMintingLimit = 2;
        reserveList.reserveListMintingCount = 3500;
        reserveList.reserveListMintingPrice = 0.05 ether;
        reserveList.reserveListMintingTime = 1633046400; // to be changed

        //Public Mint Setup
        publicMint.mintingLimit = 2;
        publicMint.mintingPrice = 0.05 ether;
    }

    function togglePublicMint() external onlyOwner {
        isPublicMinting = !isPublicMinting;
        publicMint.mintingCount = masterList.masterListMintingCount + reserveList.reserveListMintingCount;
    }

    function setMintingContract(address _mintingContract) external onlyOwner {
        mintingContract = IPassengersMintingContract(_mintingContract);
    }

    function mintMasterList(uint256 _amount, whitelist memory _signature) external payable {
        require (!isPublicMinting, "Public Minting is active");
        require (_amount <=2 && _amount > 0, "You can only mint max 2 tokens at a time");
        require (!whitelistMintTransactionTracker[msg.sender], "You have already minted from the master list");
        require (block.timestamp >= masterList.masterListMintingTime, "Minting not started yet"); //done
        require (msg.value == masterList.masterListMintingPrice * _amount, "Incorrect amount"); // done
        require (getSigner(_signature) == designatedSigner, "Incorrect signature"); // done
        require (_signature.userAddress == msg.sender, "Incorrect Caller"); // done
        require (_signature.listType == 1, "Incorrect List Type"); // done
        require (masterList.masterListMintingLimit + reserveList.reserveListMintingLimit >= _amount, "Minting limit over"); // done
        whitelistMintTransactionTracker[msg.sender] = true;
        if (_amount > 1) {
            if (reserveList.reserveListMintingCount >= 1 && masterList.masterListMintingCount >= 1) {
                reserveList.reserveListMintingCount-=1;
                reserveList.mintFromReserveList[msg.sender] = 1;
                masterList.masterListMintingCount-=1;
                masterList.mintFromMasterList[msg.sender] = 1;
                mintingContract.mint(msg.sender, 2);
            }
            else if (reserveList.reserveListMintingCount >= _amount && masterList.masterListMintingCount < 1) {
                reserveList.reserveListMintingCount-=_amount;
                reserveList.mintFromReserveList[msg.sender] = _amount;
                mintingContract.mint(msg.sender, 2);
            } else {
                revert MintingLimitOver();
            }
        } else {
            if (masterList.masterListMintingCount >= 1) {
                masterList.masterListMintingCount-=1;
                masterList.mintFromMasterList[msg.sender] = 1;
                mintingContract.mint(msg.sender, 1);
            } else if (reserveList.reserveListMintingCount >= 1) {
                reserveList.reserveListMintingCount-=1;
                reserveList.mintFromReserveList[msg.sender] = 1;
                mintingContract.mint(msg.sender, 1);
            }
            else {
                revert MintingLimitOver();
            }
        }
    }

    function mintReserveList(uint256 _amount, whitelist memory _signature) external payable {
        require (!isPublicMinting, "Public Minting is active");
        require (_amount <=2 && _amount > 0, "You can only mint max 2 tokens at a time");
        require (!whitelistMintTransactionTracker[msg.sender], "You have already minted from the reserve list");
        require (block.timestamp >= reserveList.reserveListMintingTime, "Minting not started yet"); //done
        require (reserveList.reserveListMintingCount >= _amount, "Minting limit over");
        require (msg.value == reserveList.reserveListMintingPrice * _amount, "Incorrect amount for reserve list"); // done
        require (getSigner(_signature) == designatedSigner, "Incorrect signature");
        require (_signature.userAddress == msg.sender, "Incorrect Caller");
        require (_signature.listType == 2, "Incorrect List Type");
        whitelistMintTransactionTracker[msg.sender] = true;
        reserveList.reserveListMintingCount -= _amount;
        reserveList.mintFromReserveList[msg.sender] = _amount;
        mintingContract.mint(msg.sender, _amount);
    }

    function mintPublic( uint256 _amount) external payable {
        require (_amount <= publicMint.mintingLimit && _amount > 0, "You can only mint max 2 tokens at a time");
        require (isPublicMinting, "Public minting is not active");
        require (!publicMintTransactionTracker[msg.sender], "You have already minted from the public list");
        require (publicMint.mintingCount >= _amount, "Minting limit over");
        require (msg.value == publicMint.mintingPrice * _amount, "Public Mint Incorrect amount");
        publicMintTransactionTracker[msg.sender] = true;
        publicMint.mintingCount -= _amount;
        mintingContract.mint(msg.sender, _amount);
    }

    function changePrice (uint256 _masterListPrice, uint256 _reserveListPrice, uint256 _publicMintPrice) external onlyOwner {
        masterList.masterListMintingPrice = _masterListPrice;
        reserveList.reserveListMintingPrice = _reserveListPrice;
        publicMint.mintingPrice = _publicMintPrice;
    }

    function changeTime (uint256 _masterListTime, uint256 _reserveListTime) external onlyOwner {
        masterList.masterListMintingTime = _masterListTime;
        reserveList.reserveListMintingTime = _reserveListTime;
    }

    function changeCount (uint256 _masterListCount, uint256 _reserveListCount) external onlyOwner {
        masterList.masterListMintingCount = _masterListCount;
        reserveList.reserveListMintingCount = _reserveListCount;
    }
}