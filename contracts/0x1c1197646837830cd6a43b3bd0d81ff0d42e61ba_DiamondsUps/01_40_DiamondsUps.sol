// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "IERC721.sol";
import "DefaultOperatorFiltererUpgradeable.sol";
import "ERC721xUpgradeable.sol";
import "GenesisPass.sol";
import "Merkle.sol";
import "IAggregatorV3Interface.sol";

error NotAuthorised();

// TODO: add source of randomness to be revealed that allows to construct how colours were attributed to each diamond
contract DiamondsUps is ERC721xUpgradeable, DefaultOperatorFiltererUpgradeable ,Merkle {
	using Strings for uint256;

	IAggregatorV3Interface immutable public ETH_FEED_USD = IAggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
	IAggregatorV3Interface immutable public EUR_FEED_USD = IAggregatorV3Interface(0xb49f677943BC038e9857d61E7d053CaA2C1734C1);
	// IAggregatorV3Interface immutable public ETH_FEED_USD = IAggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
	// IAggregatorV3Interface immutable public EUR_FEED_USD = IAggregatorV3Interface(0x44390589104C9164407A0E0562a9DBe6C24A0E05);
	uint256 immutable public MAX_MINTABLE;
	address immutable public PASS;
	uint256 immutable public MAX_AMOUNT = 5;

	address payable public recipient;
	uint256 public growthStages;
	string public updateableURI;
	uint256 public counter;
	uint256 public passMinted;
	uint256 public currentPrio;

	bool public killStage0;

	mapping(uint256 => uint256) public diamondStagesCounts;
	mapping(uint256 => uint256) public diamondStages;
	mapping(uint256 => uint256) public stagePrice;
	mapping(uint256 => uint256) public stageDuration;
	mapping(uint256 => mapping(uint256 => uint256)) public growthMap;

	mapping(address => bool) public operators;

	constructor (address _pass, uint256 _max) {
		PASS = _pass;
		MAX_MINTABLE = _max;
	}

	function initialize(string memory _name, string memory _symbol, address _rec) public initializer {
		__ERC721x_init(_name, _symbol);
		__DefaultOperatorFilterer_init();
		recipient = payable(_rec);
	}

	modifier authorised() {
		if (!operators[msg.sender]) revert NotAuthorised();
		_;
	}

	modifier onlyRecipient() {
		if (msg.sender != address(recipient)) revert("Diamonds: !recipient");
		_;
	}

	function updateRecipient(address _newRecipient) external onlyRecipient {
		recipient = payable(_newRecipient);
	}

	function fetch() external onlyRecipient {
		(bool res, ) = recipient.call{value:address(this).balance}("");
		require(res);
	}

	function udpateMerkleRoot(bytes32 _newRoot) external onlyOwner {
		merkleRoot = _newRoot;
	}

	function setPrio(uint256 _prio) external onlyOwner {
		currentPrio = _prio;
	}

	function executeOrder66(bool _val) external onlyOwner {
		killStage0 = _val;
	}

	function updateURI(string calldata _newURI) external onlyOwner {
		updateableURI = _newURI;
	}

	function pushNewStage(uint256 _price, uint256 _duration) external onlyOwner {
		stagePrice[++growthStages] = _price;
		stageDuration[growthStages] = _duration;
	}

	function updateAuthorised(address _operator, bool _val) external onlyOwner {
		operators[_operator] = _val;
	}

	function mintWithProof(uint256 _index, uint256 _amount, uint256 _prio, bytes32[] calldata _proof) external {
		uint256 _currentPrio = currentPrio;
		if (_prio > _currentPrio) revert("prio");
		
		if (_currentPrio < 10) {
			if (counter >= MAX_MINTABLE - 77) revert("!mint");
			_claim(_index, msg.sender, 1, _prio, _proof);
		}
		else {
			if (counter + _amount - 1 >= MAX_MINTABLE - 77) revert("!mint");
			_verify(_index, msg.sender, 1, _prio, _proof);
		}
		if (_currentPrio < 10)
			_mint(msg.sender, ++counter + 77);
		else {
			if (balanceOf(msg.sender) + _amount > 6) revert("Diamonds: Max mint exceed");
			uint256 _counter = counter;
			for (uint256 i = 0; i < _amount; i++)
				_mint(msg.sender, ++_counter + 77);
			counter += _amount;
		}
	}

	function mintWithAtomsTo(address _to, uint256 _stage, uint256 _id, bool _pass) external authorised {
		_mint(_to, _id);
		if (_pass)
			_tryMintPass(_to);
		diamondStages[_id] = _stage;
		diamondStagesCounts[_stage]++;
		growthMap[_id][_stage] = block.timestamp;
	}

	function buyCarbonAtoms(uint256 _tokenId, uint256 _amount, uint256 _passId) external payable {
		if (ownerOf(_tokenId) != msg.sender) revert("!owner");
		uint256 lastStage = growthStages;
		uint256 currentDiamondStage = diamondStages[_tokenId];
		if (_amount == 0) revert("!0");
		if (currentDiamondStage == lastStage) revert("!grow");
		if (lastStage - currentDiamondStage < _amount) revert("!amount");
		uint256 valueToPay = getEURPriceInEth(_sumStages(currentDiamondStage, _amount));
		if (msg.value < valueToPay) revert("!price");

		uint256 passId = _passId;
		if (currentDiamondStage < 3 && currentDiamondStage + _amount >= 3)
			passId = _tryMintPass(msg.sender);
		if (currentDiamondStage + _amount >= 3) {
			if (passId == 0 || passId > 777) revert ("Invalid pass");
			if (IERC721(PASS).ownerOf(passId) != msg.sender) revert("!pass owner");
		}
		diamondStages[_tokenId] += _amount;
		if (currentDiamondStage > 0)
			diamondStagesCounts[currentDiamondStage]--;
		diamondStagesCounts[currentDiamondStage + _amount]++;
		growthMap[_tokenId][currentDiamondStage + _amount] = block.timestamp;

		if (valueToPay > msg.value) {
			(bool res, ) = msg.sender.call{value:msg.value - valueToPay}("");
			require(res);
		}
	}

	function diamondStageToShow(uint256 _tokenId) external view returns(uint256, uint256) {
		uint256 currentStage = diamondStages[_tokenId];
		uint256[] memory stageDur = new uint256[](currentStage);
		uint256 wait;

		uint256 logAmount;
		// set all times for each stages
		for (uint256 i = 0; i < currentStage; i++) {
			stageDur[i] = stageDuration[i + 1];
			if (growthMap[_tokenId][i + 1] > 0) {
				logAmount++;
				if (wait == 0)
					wait = block.timestamp - growthMap[_tokenId][i + 1];
			}
		}
		// many growth logs
		if (logAmount > 1) {
			uint256 storedEpoch;
			uint256 totalEpoch;
			uint256 start;
			for (uint256 i = 0; i < currentStage; i++) {
				totalEpoch += stageDur[i];
				if (growthMap[_tokenId][i + 1] > 0) {
					if (start == 0) {
						start = growthMap[_tokenId][i + 1];
						storedEpoch = totalEpoch;
						totalEpoch = 0;
					}
					else {
						uint256 lapsed = growthMap[_tokenId][i + 1] - start;
						if (lapsed > storedEpoch)
							wait -= lapsed - storedEpoch;
						storedEpoch = totalEpoch;
						totalEpoch = 0;
						start = growthMap[_tokenId][i + 1];
					}
				}
			}			
		}
		for (uint256 i = 0; i < currentStage; i++) {
			if (wait >= stageDur[i]) {
				wait -= stageDur[i];
			}
			else {
				return(i, stageDur[i] - wait);
			}
		}
		return (currentStage, 0);
	}

	function _sumStages(uint256 _stage, uint256 _len) internal view returns(uint256 sum) {
		uint256 lastStage = _stage + _len;
		for(; _stage < lastStage; _stage++)
			sum += stagePrice[_stage + 1];
	}

	function getEURPriceInEth(uint256 _price) public view returns(uint256) {
		// return _price;
		(,int256 ethPrice,,,) = ETH_FEED_USD.latestRoundData();
		(,int256 eurPrice,,,) = EUR_FEED_USD.latestRoundData();
		return _price * uint256(eurPrice) * 1e18 / uint256(ethPrice);
	}

	function _tryMintPass(address _user) internal returns(uint256 passId) {
		if (passMinted < 700) {
			passId = ++passMinted + 77;
			GenesisPass(PASS).mint(_user, passId);
		}
	}

	function _baseURI() internal view override returns (string memory) {
        return updateableURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ?
			string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

	function _min(uint256 a, uint256 b) internal pure returns(uint256) {
		return a > b ? b : a;
	}

	function _beforeTokenTransfer(address from, address to, uint256 firstTokenId) internal override {
		uint256 stage = diamondStages[firstTokenId];

		if (stage == 0 && killStage0) revert();
	}

    function setApprovalForAll(address operator, bool approved) public override(ERC721Upgradeable, IERC721Upgradeable) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override(ERC721Upgradeable, IERC721Upgradeable) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721xUpgradeable) onlyAllowedOperator(from) {
        ERC721xUpgradeable.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721Upgradeable, IERC721Upgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721xUpgradeable)
        onlyAllowedOperator(from)
    {
        ERC721xUpgradeable.safeTransferFrom(from, to, tokenId, data);
    }
}