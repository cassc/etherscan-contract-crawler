// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract MCN is ERC721A, Ownable {
    enum NinjaStatus {
        FOCUS,
        STRIVE,
        DESERT,
        GAME,
        DOZE
    }

    string public baseTokenURI;

    string public ninjaDieTokenURI;

    uint256 constant public maxSupply = 8000;

    uint256 public whitelistStartTime = 1667473200 - 30; // Nov 3 2022 20:00:00 GMT+09 - 30s

    uint256 public publicStartTime = 1667480400 - 30; // Nov 3 2022 22:00:00 GMT+09 - 30s

    uint256 public whitelistPrice = 0.003 ether;

    uint256 public publicPrice = 0.005 ether;

    uint256 public whitelistMinted;

    mapping(address => uint256) public whitelistMintedMap;

    mapping(address => uint256) public publicMintedMap;

    bytes32 private _merkleRoot;

	uint256 public totalAirdropped = 0;

    uint256 constant public DAY_SECOND = 24 * 60 * 60;

    uint256 public ninjaMaxLevel = 1000; // Level 10

    mapping(uint256 => uint256[]) public ninjaTrainTimesMap;

    mapping(uint256 => uint256) public ninjaBaseLevelMap;

    mapping(uint256 => bool) public ninjaDieMap;

    address public ninjaLifeController;

    address public CNP = 0x845a007D9f283614f403A24E3eB3455f720559ca;

    address public CNPJ = 0xFE5A28F19934851695783a0C8CCb25d678bB05D3;

    address public CNPR = 0x836B4d9C0F01275A28085AceF53AC30460f58242;

    constructor(string memory baseTokenURI_, bytes32 merkleRoot_) ERC721A("MCN", "MCN") {
        baseTokenURI = baseTokenURI_;
        _merkleRoot = merkleRoot_;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Must from user");
        _;
    }

    function whitelistMint(uint256 quantity, bytes32[] calldata _merkleProof) external callerIsUser payable {
        require(block.timestamp >= whitelistStartTime, "Not in whitelist stage");
        require(_totalMinted() + quantity <= maxSupply, "Exceed supply");
        require(whitelistMinted + quantity <= 1500, "Exceed whitelist supply");
        require(isInWhitelist(msg.sender, _merkleProof) || isCNPOwner(msg.sender), "Caller can not whitelist mint");
        require(whitelistMintedMap[msg.sender] + quantity <= 5, "Exceed per-user whitelist supply");
        require(msg.value >= whitelistPrice * quantity, "Not enough ether paid for");

        whitelistMinted += quantity;
        whitelistMintedMap[msg.sender] += quantity;

        _safeMint(msg.sender, quantity);
    }

    function publicMint(uint256 quantity) external callerIsUser payable {
        require(block.timestamp >= publicStartTime || whitelistMinted >= 1500, "Not in public stage");
        require(_totalMinted() + quantity <= maxSupply, "Exceed supply");
        require(publicMintedMap[msg.sender] + quantity <= 5, "This address has finished public mint");
        require(msg.value >= publicPrice * quantity, "Not enough ether paid for");

        publicMintedMap[msg.sender] += quantity;

        _safeMint(msg.sender, quantity);
    }

    function isInWhitelist(address _address, bytes32[] calldata _signature) public view returns (bool) {
        return MerkleProof.verify(_signature, _merkleRoot, keccak256(abi.encodePacked(_address)));
    }

    function isCNPOwner(address owner) public view returns (bool) {
        return ERC721A(CNP).balanceOf(owner) > 0 || ERC721A(CNPJ).balanceOf(owner) > 0 || ERC721A(CNPR).balanceOf(owner) > 0;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory baseURI = _baseURI();

        if (ninjaDieMap[tokenId] && bytes(ninjaDieTokenURI).length != 0) {
            return ninjaDieTokenURI;
        }

        return string(
            abi.encodePacked(
                baseURI,
                _toString(getNinjaLevel(tokenId) / 100),
                "/",
                _toString(uint256(getNinjaStatus(tokenId))),
                "/",
                _toString(tokenId),
                ".json"
            )
        );
    }

    function totalMinted() public view returns (uint256) {
		return _totalMinted();
	}

    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
		uint256 index = 0;
		uint256 hasMinted = _totalMinted();
		uint256 tokenIdsLen = balanceOf(owner);
		uint256[] memory tokenIds = new uint256[](tokenIdsLen);

		for (uint256 tokenId = 1; index < tokenIdsLen && tokenId <= hasMinted; tokenId++) {
			if (owner == ownerOf(tokenId)) {
				tokenIds[index] = tokenId;
				index++;
			}
		}

		return tokenIds;
	}


    /********** 721A HOOK START **********/
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);

        if (from == address(0)) {
            for (uint i = 0; i < quantity; i++) {
                uint256 currentToke = startTokenId + i;
                ninjaBaseLevelMap[currentToke] = 100;
                ninjaTrainTimesMap[currentToke].push(block.timestamp);
            }
        }
    }
    /********** 721A HOOK END **********/


    /********** NINJA PLAY START **********/
    function getNinjaTrainTimes(uint256 tokenId) public view returns (uint256[] memory) {
        return ninjaTrainTimesMap[tokenId];
    }

    function getNinjaLastTrainTime(uint256 tokenId) public view returns (uint256) {
        uint256[] memory times = ninjaTrainTimesMap[tokenId];
        return times[times.length - 1];
    }

    function getNinjaStatus(uint256 tokenId) public view returns (NinjaStatus) {
        uint256 trainDaysSinceLast = (block.timestamp - getNinjaLastTrainTime(tokenId)) / DAY_SECOND;
        if (trainDaysSinceLast >= 14) {
            return NinjaStatus.DOZE;
        }
        if (trainDaysSinceLast >= 9) {
            return NinjaStatus.GAME;
        }
        if (trainDaysSinceLast >= 5) {
            return NinjaStatus.DESERT;
        }
        if (trainDaysSinceLast >= 2) {
            return NinjaStatus.STRIVE;
        }
        return NinjaStatus.FOCUS;
    }

    function getNinjaLevel(uint256 tokenId) public view returns (uint256) {
        uint256 trainSecondsSinceLast = block.timestamp - getNinjaLastTrainTime(tokenId);
        uint256 trainDaysSinceLast = trainSecondsSinceLast / DAY_SECOND;
        uint256 upgradeLevel = 0;

        if (trainDaysSinceLast >= 14) {
            upgradeLevel = 400;
        } else if (trainDaysSinceLast >= 9) {
            upgradeLevel = 300 + (((trainSecondsSinceLast - 9 * DAY_SECOND) * 100) / (5 * DAY_SECOND));
        } else if (trainDaysSinceLast >= 5) {
            upgradeLevel = 200 + (((trainSecondsSinceLast - 5 * DAY_SECOND) * 100) / (4 * DAY_SECOND));
        } else if (trainDaysSinceLast >= 2) {
            upgradeLevel = 100 + (((trainSecondsSinceLast - 2 * DAY_SECOND) * 100) / (3 * DAY_SECOND));
        } else {
            upgradeLevel = (trainSecondsSinceLast * 100) / (2 * DAY_SECOND);
        }

        return Math.min(ninjaBaseLevelMap[tokenId] + upgradeLevel, ninjaMaxLevel);
    }

    function getNinjasLevel(uint256[] calldata tokenIds) public view returns (uint256[] memory) {
        uint256 tokenIdsLen = tokenIds.length;
		uint256[] memory levels = new uint256[](tokenIdsLen);

		for (uint256 index = 0; index < tokenIdsLen; index++) {
            levels[index] = getNinjaLevel(tokenIds[index]);
		}

		return levels;
    }

    function ninjaTrain(uint256 tokenId) external {
        require(block.timestamp - getNinjaLastTrainTime(tokenId) >= DAY_SECOND, "Training needs to be separated by 24 hours.");
        ninjaBaseLevelMap[tokenId] = getNinjaLevel(tokenId);
        ninjaTrainTimesMap[tokenId].push(block.timestamp);
    }

    function getNinjaByLevel(uint256 minLevel, uint256 maxLevel) external view returns (uint256[] memory) {
        require(minLevel <= maxLevel, "Parameter error");
        uint256[] memory tokenIds = new uint256[](0);
        uint256 totalMinted_ = _totalMinted();

        for (uint256 tokenId = 1; tokenId < totalMinted_; tokenId++) {
            uint256 _level = getNinjaLevel(tokenId);
            if (minLevel <= _level &&  _level <= maxLevel) {
                tokenIds = _numListPush(tokenIds, tokenId);
            }
        }
        return tokenIds;
    }

    function _numListPush(uint256[] memory numList, uint256 num) private pure returns(uint256[] memory) {
        uint256[] memory temp = new uint256[](numList.length + 1);
        for (uint256 index = 0; index < numList.length; index++) {
            temp[index] = numList[index];
        }
        temp[temp.length - 1] = num;
        return temp;
    }

    function ninjaDie(uint256 tokenId) external {
        require(msg.sender == ninjaLifeController, "Permission denied");
        ninjaDieMap[tokenId] = true;
    }

    function ninjaRelive(uint256 tokenId) external {
        require(msg.sender == ninjaLifeController, "Permission denied");
        ninjaDieMap[tokenId] = false;
    }
    /********** NINJA PLAY END **********/


    /********** MANAGER CONTRACT START **********/
    function setNinjaMaxLevel(uint256 max) external onlyOwner {
        ninjaMaxLevel = max;
    }

    function setWhitelistStartTime(uint256 startime) external onlyOwner {
        whitelistStartTime = startime;
    }

    function setPublicStartTime(uint256 startime) external onlyOwner {
        publicStartTime = startime;
    }

    function setWhitelistPrice(uint256 price) external onlyOwner {
        whitelistPrice = price;
    }

    function setPublicPrice(uint256 price) external onlyOwner {
        publicPrice = price;
    }

    function setMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        _merkleRoot = merkleRoot;
    }

    function setBaseURI(string calldata baseTokenURI_) external onlyOwner {
        baseTokenURI = baseTokenURI_;
    }

    function setNinjaDieURI(string calldata ninjaDieTokenURI_) external onlyOwner {
        ninjaDieTokenURI = ninjaDieTokenURI_;
    }

    function setNinjaLifeController(address _ninjaLifeController) external onlyOwner {
        ninjaLifeController = _ninjaLifeController;
    }

    function airdrop(address[] calldata addressList, uint256 quantity) external onlyOwner {
		uint256 total = addressList.length * quantity;
		require(
			_totalMinted() + total <= maxSupply,
			"Exceed nft max supply"
		);

		totalAirdropped += total;

		for (uint256 index = 0; index < addressList.length; index++) {
			_mint(addressList[index], quantity);
		}
	}

    function withdraw() external onlyOwner {
        (bool success,) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Withdraw failed.");
    }

    function withdraw(address to) external onlyOwner {
        (bool success,) = payable(to).call{value: address(this).balance}("");
        require(success, "Withdraw failed.");
    }

    function withdraw(address to, uint256 value) external onlyOwner {
        (bool success,) = payable(to).call{value: value}("");
        require(success, "Withdraw failed.");
    }
    /********** MANAGER CONTRACT END **********/


    /********** 721A CONFIG START **********/
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
    /********** 721A CONFIG END **********/
}