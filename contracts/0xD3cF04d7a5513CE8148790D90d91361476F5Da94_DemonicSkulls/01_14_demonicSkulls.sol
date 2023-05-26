// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


abstract contract CryptoSkullsContract {
    function ownerOf(uint256 tokenId) public view virtual returns (address);
    function balanceOf(address account) public view virtual returns (uint256);
}

abstract contract DemonsBloodContract {
    function balanceOf(address account, uint256 tokenId) public view virtual returns (uint256);
    function burnForAddress(uint256 typeId, address burnTokenAddress, uint256 amount) external virtual;
}

abstract contract RestorationContract {
    function exists(address account) public view virtual returns (uint256[] memory, bool[] memory);
}

contract DemonicSkulls is ERC721Enumerable, Ownable, ReentrancyGuard {
    CryptoSkullsContract private cryptoSkullsContract;
    DemonsBloodContract private demonsBloodContract;
    address private restorationContract;

    uint256 public levelTwoMintedAmount;
    uint256 public levelThreeMintedAmount;

    uint256 public maxMintsPerTxn = 5;

    uint256 public levelTwoMintPrice = 0.7 ether;

    bool public saleIsActive = false;
    bool public claimIsActive = false;

    string public baseURI;

    uint256 public levelTwoIndex = 9999;

    address public withdrawalWallet;

    mapping (uint256 => bool) public claimedTokens;
    mapping (address => uint256) public levelTwoClaimers;
    mapping (address => uint256) public levelThreeClaimers;
    mapping (uint256 => bool) public lordsIds;

    uint256 private constant COMMON_BLOOD_TYPE = 0;
    uint256 private constant LORD_BLOOD_TYPE = 1;

    uint256 private constant LEVEL_ONE_BLOOD_AMOUNT = 1;
    uint256 private constant LEVEL_TWO_BLOOD_AMOUNT = 3;
    uint256 private constant LEVEL_THREE_BLOOD_AMOUNT = 5;
    uint256 private constant LORD_BLOOD_AMOUNT = 1;

    uint256 private MAX_LEVEL_TWO_AMOUNT = 2500;

    constructor(string memory name,
        string memory symbol,
        string memory _baseUri,
        address skullsContract,
        address bloodsContract) ERC721(name, symbol) {
        baseURI = _baseUri;

        cryptoSkullsContract = CryptoSkullsContract(skullsContract);
        demonsBloodContract = DemonsBloodContract(bloodsContract);

        lordsIds[9] = true;
        lordsIds[19] = true;
        lordsIds[20] = true;
        lordsIds[24] = true;
        lordsIds[27] = true;
        lordsIds[36] = true;
        lordsIds[41] = true;
        lordsIds[42] = true;
        lordsIds[43] = true;
        lordsIds[70] = true;
    }

    function setWithdrawalWallet(address wallet) public onlyOwner {
        withdrawalWallet = wallet;
    }

    function setRestorationContract(address restorationContractAddress) public onlyOwner {
        restorationContract = restorationContractAddress;
    }

    function setMaxMintsPerTxn(uint256 amount) public onlyOwner {
        maxMintsPerTxn = amount;
    }

    function setLevelTwoMintPrice(uint256 price) public onlyOwner {
        levelTwoMintPrice = price;
    }

    function withdraw() public onlyOwner {
        require(payable(withdrawalWallet).send(address(this).balance));
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipClaimState() public onlyOwner {
        claimIsActive = !claimIsActive;
    }

    function mintForAddress(address wallet, uint256 bloodAmount, uint256 id) virtual external {
        require(msg.sender == restorationContract, "Invalid caller");

        if (bloodAmount == LEVEL_ONE_BLOOD_AMOUNT) {
            require(id >= 0 && id <= 9999, "Wrong ID");

            _safeMint(wallet, id);
        } else if (bloodAmount == LEVEL_TWO_BLOOD_AMOUNT) {
            require(id > 9999 && id < 12500, "Wrong ID");

            levelTwoClaimers[wallet] += 1;
            levelTwoMintedAmount++;
            levelTwoIndex++;

            _safeMint(wallet, id);
        } else if (bloodAmount == LEVEL_THREE_BLOOD_AMOUNT) {
            require(id > 12499 && id < 12650, "Wrong ID");

            levelThreeClaimers[wallet] += 1;
            levelThreeMintedAmount++;

            _safeMint(wallet, id);
        }
    }

    function setClaimedId(uint256 id) virtual external {
        require(msg.sender == restorationContract, "Invalid caller");
        require(id >= 0 && id <= 9999, "Wrong ID");

        claimedTokens[id] = true;
    }

    function _mintLevel2(address wallet) private {
        uint256 nextId = levelTwoIndex + 1;
        require(nextId > 9999 && nextId < 12500, "Wrong ID");

        levelTwoIndex = nextId;
        levelTwoClaimers[wallet] += 1;
        levelTwoMintedAmount++;

        _safeMint(wallet, nextId);
    }

    function mintRefund(address wallet) virtual external {
        require(msg.sender == restorationContract, "Invalid caller");

        for (uint256 i = 0; i < 2; i++) {
            _mintLevel2(wallet);
        }
    }

    function claimLords(uint256[] memory ids) public {
        require(claimIsActive, "Claim not active");
        require(demonsBloodContract.balanceOf(msg.sender, LORD_BLOOD_TYPE) >= ids.length, "Too few Blood");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];

            require(lordsIds[id], "Can only claim Lord");
            require(!claimedTokens[id], "Already claimed");
            require(cryptoSkullsContract.ownerOf(id) == msg.sender, "Must own original Lord");

            claimedTokens[id] = true;
            demonsBloodContract.burnForAddress(LORD_BLOOD_TYPE, msg.sender, LORD_BLOOD_AMOUNT);

            _safeMint(msg.sender, id);
        }
    }

    function claimSkulls(uint256[] memory ids, uint256 bloodAmount) public {
        require(claimIsActive, "Claim not active");
        require(bloodAmount == LEVEL_ONE_BLOOD_AMOUNT || bloodAmount == LEVEL_TWO_BLOOD_AMOUNT, "Wrong level");
        require(demonsBloodContract.balanceOf(msg.sender, COMMON_BLOOD_TYPE) >= bloodAmount * ids.length, "Too few Blood");

        if (bloodAmount == LEVEL_TWO_BLOOD_AMOUNT) {
            require(levelTwoMintedAmount + ids.length <= MAX_LEVEL_TWO_AMOUNT,  "Exceeds max amount");
            require((ids.length + levelTwoClaimers[msg.sender]) <= 50, "Limit is 50 L2 per wallet");
        }

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];

            require(id >= 0 && id <= 9999, "Wrong ID");
            require(!lordsIds[id], "Can't mint Lord");
            require(!claimedTokens[id], "Already claimed");
            require(cryptoSkullsContract.ownerOf(id) == msg.sender, "Must own CryptoSkull");

            if (bloodAmount == LEVEL_ONE_BLOOD_AMOUNT) {
                claimedTokens[id] = true;

                demonsBloodContract.burnForAddress(COMMON_BLOOD_TYPE, msg.sender, LEVEL_ONE_BLOOD_AMOUNT);
                _safeMint(msg.sender, id);
            } else if (bloodAmount == LEVEL_TWO_BLOOD_AMOUNT) {
                uint256 nextId = levelTwoIndex + 1;
                require(nextId > 9999 && nextId < 12500, "Wrong ID");

                claimedTokens[id] = true;

                levelTwoIndex = nextId;
                levelTwoClaimers[msg.sender] += 1;
                levelTwoMintedAmount++;

                demonsBloodContract.burnForAddress(COMMON_BLOOD_TYPE, msg.sender, LEVEL_TWO_BLOOD_AMOUNT);
                _safeMint(msg.sender, nextId);
            }
        }
    }

    function mint(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale not active");
        require(numberOfTokens <= maxMintsPerTxn, "Txn limit");
        require(levelTwoMintedAmount + numberOfTokens <= MAX_LEVEL_TWO_AMOUNT, "Exceeds max amount");
        require((numberOfTokens + levelTwoClaimers[msg.sender]) <= 50, "You can't mint more than 50 L2 per wallet");

        bool hasOriginalSkulls = cryptoSkullsContract.balanceOf(msg.sender) > 0;
        uint256 totalPrice = hasOriginalSkulls ? (levelTwoMintPrice * numberOfTokens) * 80 / 100 : levelTwoMintPrice * numberOfTokens;

        require(totalPrice <= msg.value, "Low ETH");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _mintLevel2(msg.sender);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }
}