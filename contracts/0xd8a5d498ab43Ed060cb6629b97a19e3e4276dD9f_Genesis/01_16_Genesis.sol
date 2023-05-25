// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract Genesis is Ownable, ERC721A, ERC2981, ReentrancyGuard, Pausable {
    using Strings for uint256;

    struct SaleInfo {
        uint8 step;
        uint16 amount;
        uint256 price;
        uint256 mintStartTime;
    }

    uint8 private constant FREE_MINT_STEP = 0;
    uint8 private constant MINT_LIST_STEP = 1;
    uint8 private constant WHITE_LIST_STEP = 2;
    uint8 private constant PUBLIC_STEP = 3;
    uint8 private constant WAIT_LIST_STEP = 4;
    uint8 private constant STEP_COUNT = 5;

    string private metadataUri;
    uint256 public constant maxSupply = 10000;

    mapping(address => uint8) public freeMintAddress;
    mapping(address => uint8) public mintListAddress;
    mapping(address => uint8) public whiteListAddress;
    mapping(address => uint8) public publicAddress;
    mapping(address => uint8) public waitListAddress;

    SaleInfo[] public saleInfoList;
    uint256[] private accumulatedSaleAmount;

    bool private isRevealed = false;

    constructor(
        uint16[] memory _amounts,
        uint256[] memory _prices,
        uint256[] memory _mintStartTimes,
        string memory _metadataUri,
        address _royaltyReceiver,
        uint96 _royaltyFeeNumerator
    ) ERC721A("Genesis", "GENESIS") {
        require(
            _amounts.length + _prices.length + _mintStartTimes.length == (STEP_COUNT) * 3,
            "Invalid Argument : param length"
        );
        require(_amounts[0] + _amounts[1] + _amounts[2] + _amounts[3] <= maxSupply, "Invalid Argument : maxSupply");

        for (uint8 i = 0; i < STEP_COUNT; i++) {
            saleInfoList.push(SaleInfo(i, _amounts[i], _prices[i], _mintStartTimes[i]));

            if (i > 0) {
                accumulatedSaleAmount.push(accumulatedSaleAmount[i - 1] + _amounts[i]);
            } else {
                accumulatedSaleAmount.push(_amounts[i]);
            }
        }

        metadataUri = _metadataUri;
        _setDefaultRoyalty(_royaltyReceiver, _royaltyFeeNumerator);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (!isRevealed) {
            return string(abi.encodePacked(metadataUri, "prereveal"));
        }
        return string(abi.encodePacked(metadataUri, Strings.toString(_tokenId)));
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(metadataUri, "contractURI"));
    }

    function mint(uint8 amount, uint8 step) external payable nonReentrant whenNotPaused isNotContract {
        require(_checkMintStepValid(step), "Not exist mint step");

        uint8 _currStep = getCurrentStep();
        if (_currStep != step) {
            revert("Steps that have not started or are finished");
        }

        uint256 _price = saleInfoList[step].price * amount;
        require(msg.value == _price, "Invalid ETH balance");

        require(_totalMinted() + amount <= accumulatedSaleAmount[step], "Sold out in this step");
        if (step == FREE_MINT_STEP) {
            _mintForEachStep(amount, freeMintAddress);
        } else if (step == MINT_LIST_STEP) {
            _mintForEachStep(amount, mintListAddress);
        } else if (step == WHITE_LIST_STEP) {
            _mintForEachStep(amount, whiteListAddress);
        } else if (step == PUBLIC_STEP) {
            _mintForEachStep(amount, publicAddress);
        } else if (step == WAIT_LIST_STEP) {
            _mintForEachStep(amount, waitListAddress);
        }
    }

    function getCurrentStep() public view returns (uint8) {
        uint8 _step;
        for (_step = STEP_COUNT - 1; _step >= 0; _step--) {
            if (block.timestamp >= saleInfoList[_step].mintStartTime) {
                return _step;
            }
        }
        revert("Minting hasn't started yet");
    }

    function isSoldout(uint8 step) public view returns (bool) {
        require(_checkMintStepValid(step), "Not exist mint step");
        return _totalMinted() == accumulatedSaleAmount[step];
    }

    function getMintableAmount(uint8 step) public view returns (uint256) {
        require(_checkMintStepValid(step), "Not exist mint step");
        return accumulatedSaleAmount[step] - _totalMinted();
    }

    function _mintForEachStep(uint8 amount, mapping(address => uint8) storage allowList) private {
        require(allowList[msg.sender] - amount >= 0, "Don't have mint authority");
        allowList[msg.sender] -= amount;
        _safeMint(msg.sender, amount);
    }

    function _checkMintStepValid(uint8 step) internal pure returns (bool) {
        return step < STEP_COUNT;
    }

    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) {
            revert("Ether transfer failed");
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _setMintAuthority(
        address _address,
        uint8 step,
        uint8 _amount
    ) private {
        require(_address != address(0), "address can't be 0");
        require(_checkMintStepValid(step), "Not exist mint step");

        if (step == FREE_MINT_STEP) {
            freeMintAddress[_address] = _amount;
        } else if (step == MINT_LIST_STEP) {
            mintListAddress[_address] = _amount;
        } else if (step == WHITE_LIST_STEP) {
            whiteListAddress[_address] = _amount;
        } else if (step == PUBLIC_STEP) {
            publicAddress[_address] = _amount;
        } else if (step == WAIT_LIST_STEP) {
            waitListAddress[_address] = _amount;
        } else {
            revert("Not exist mint step");
        }
    }

    function setBulkMintAuthority(
        address[] calldata _addressList,
        uint8 step,
        uint8[] calldata _amountList
    ) external onlyOwner {
        require(_addressList.length == _amountList.length, "Invalid argument : different argument size");

        for (uint256 i = 0; i < _addressList.length; i++) {
            _setMintAuthority(_addressList[i], step, _amountList[i]);
        }
    }

    function setSaleAmount(uint16[] memory _amounts) external onlyOwner {
        require(_amounts.length == STEP_COUNT, "Invalid argument");
        for (uint8 i = 0; i < STEP_COUNT; i++) {
            saleInfoList[i].amount = _amounts[i];
            if (i > 0) {
                accumulatedSaleAmount[i] = accumulatedSaleAmount[i - 1] + _amounts[i];
            } else {
                accumulatedSaleAmount[i] = _amounts[i];
            }
        }

        require(maxSupply >= accumulatedSaleAmount[STEP_COUNT - 1], "Invalid argument : exceed maxSupply");
    }

    function setSalePrice(uint256[] memory _prices) external onlyOwner {
        require(_prices.length == STEP_COUNT, "Invalid argument");
        for (uint8 i = 0; i < STEP_COUNT; i++) {
            if (i > 0) {
                require(saleInfoList[i - 1].price <= _prices[i], "Invalid argument");
            }
            saleInfoList[i].price = _prices[i];
        }
    }

    function setMintStartTime(uint256[] memory _mintStartTimes) external onlyOwner {
        require(_mintStartTimes.length == STEP_COUNT, "Invalid argument");
        for (uint8 i = 0; i < STEP_COUNT; i++) {
            if (i > 0) {
                require(saleInfoList[i - 1].mintStartTime <= _mintStartTimes[i], "Invalid argument");
            }
            saleInfoList[i].mintStartTime = _mintStartTimes[i];
        }
    }

    function setMetadataUri(string calldata _metadataUri) external onlyOwner {
        metadataUri = _metadataUri;
    }

    function setIsReveal(bool _isReveal) external onlyOwner {
        isRevealed = _isReveal;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        super._setDefaultRoyalty(receiver, feeNumerator);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    modifier isNotContract() {
        require(msg.sender == tx.origin, "Sender is not EOA");
        _;
    }
}