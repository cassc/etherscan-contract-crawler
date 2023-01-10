// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../core/interface/IDinoMarketplace.sol";
import "../../core/interface/IDinolandNFT.sol";
import "./IFlashSaleManager.sol";

contract FlashSaleBox is ERC721Enumerable, Ownable, ReentrancyGuard {
    constructor(address _flashSaleBoxManagerAddress)
        ERC721("Flash Sale Box", "DINOFSBOX")
    {
        flashSaleBoxManagerAddress = _flashSaleBoxManagerAddress;
        boxOpenableAt = block.timestamp;
        startSaleBoxAt = block.timestamp;
        endSaleBoxAt = block.timestamp;
        maxAllocationPerWallet = 1;
        totalSellingBoxes = 10;
        totalSoldBoxes = 0;
        boxPrice = 8888 * 1e18;
    }

    using SafeMath for uint256;
    event BoxOpened(
        uint256 indexed boxId,
        address indexed owner,
        uint256 dinoId1,
        uint256 dinoId2,
        uint256 dinoId3,
        uint256 dinoId4,
        uint256 dinoId5
    );

    event BoxMinted(uint256 indexed boxId, address indexed to);
    event TokenWithdrawed(address indexed to, uint256 value);

    struct Box {
        uint256 createdAtBlock;
        uint256 createdAt;
        bool isAvailable;
    }

    Box[] boxes;
    mapping(address => bool) public minters;
    uint256 public boxOpenableAt;
    address public nftContractAddress;
    address public tokenContractAddress;
    address public flashSaleBoxManagerAddress;
    string public boxTokenURI;
    uint256 public boxPrice;
    /// @dev Time  begin and end buy box
    uint256 public startSaleBoxAt;
    uint256 public endSaleBoxAt;

    /// @dev Total boxes sale
    uint256 public totalSellingBoxes = 20;

    /// @dev Total Sold Boxes
    uint256 public totalSoldBoxes = 0;

    /// @dev Total boxes bought by address
    mapping(address => uint256) public addressToTotalBoughtBoxes;

    /// @dev Maximum buy box per walletAddress
    uint256 public maxAllocationPerWallet = 1;

    modifier noContract() {
        uint32 size;
        address _addr = msg.sender;
        assembly {
            size := extcodesize(_addr)
        }
        require(size == 0);
        require(msg.sender == tx.origin);
        _;
    }

    modifier onlyMinterOrOwner() {
        require(
            minters[msg.sender] == true || owner() == msg.sender,
            "Only minter or owner can call this function"
        );
        _;
    }

    function tokenURI(uint256 _boxId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_boxId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return boxTokenURI;
    }

    function getBoxDetail(uint256 _boxId)
        external
        view
        returns (
            uint256 createdAtBlock,
            uint256 createdAt,
            bool isAvailable,
            address owner
        )
    {
        Box memory box = boxes[_boxId];
        address boxOwner = ownerOf(_boxId);
        return (box.createdAtBlock, box.createdAt, box.isAvailable, boxOwner);
    }

    function setNftContractAddress(address _nftContractAddress)
        external
        onlyOwner
    {
        nftContractAddress = _nftContractAddress;
    }

    /// @dev Set start time of this buy box
    /// @param _time When the buy box will start
    function setStartSaleBoxAt(uint256 _time) external onlyOwner {
        startSaleBoxAt = _time;
    }

    /// @dev Set end time of this buy box
    /// @param _time When the buy box will end
    function setEndSaleBoxAt(uint256 _time) external onlyOwner {
        endSaleBoxAt = _time;
    }

    function setTokenContractAddress(address _tokenContractAddress)
        external
        onlyOwner
    {
        tokenContractAddress = _tokenContractAddress;
    }

    function setBoxManagerAddress(address _flashSaleBoxManagerAddress)
        external
        onlyOwner
    {
        flashSaleBoxManagerAddress = _flashSaleBoxManagerAddress;
    }

    function setBoxOpenableAt(uint256 _boxOpenableAt) external onlyOwner {
        require(
            _boxOpenableAt > block.timestamp,
            "Box openable at must be in the future"
        );
        boxOpenableAt = _boxOpenableAt;
    }

    function setMinter(address _minter, bool _isMinter) external onlyOwner {
        minters[_minter] = _isMinter;
    }

    function setTotalSellingBoxes(uint256 _totalSellingBoxes)
        external
        onlyOwner
    {
        require(
            _totalSellingBoxes > 0,
            "Total selling boxes must be greater than 0"
        );
        totalSellingBoxes = _totalSellingBoxes;
    }

    function setBoxPrice(uint256 _boxPrice) external onlyOwner {
        require(_boxPrice > 0, "Box price must be greater than 0");
        boxPrice = _boxPrice;
    }

    function setMaxAllocationPerWallet(uint256 _maxAllocationPerWallet)
        external
        onlyOwner
    {
        maxAllocationPerWallet = _maxAllocationPerWallet;
    }

    function _transferDinoReward(
        uint256 _dinoGenes,
        uint128 _dinoGender,
        address _receiver
    ) internal returns (uint256) {
        uint256 dinoId = IDinolandNFT(nftContractAddress).createDino(
            _dinoGenes,
            _receiver,
            _dinoGender,
            1
        );
        return dinoId;
    }

    function withdrawToken(
        address _tokenContractAddress,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        IERC20(_tokenContractAddress).transfer(_to, _amount);
        emit TokenWithdrawed(msg.sender, _amount);
    }

    function mint(address _receiver) public onlyMinterOrOwner {
        Box memory newBox = Box(block.number, block.timestamp, true);
        boxes.push(newBox);
        uint256 newBoxId = boxes.length - 1;
        _mint(_receiver, newBoxId);
        emit BoxMinted(newBoxId, _receiver);
    }

    function mintMultipleBoxes(
        address[] memory _receivers,
        uint256[] memory _quantities
    ) public onlyMinterOrOwner {
        require(
            _receivers.length == _quantities.length,
            "FlashSaleBox: Receivers and amounts must have the same length"
        );
        for (uint256 i = 0; i < _receivers.length; i++) {
            for (uint256 j = 0; j < _quantities[i]; j++) {
                Box memory newBox = Box(block.number, block.timestamp, true);
                boxes.push(newBox);
                uint256 newBoxId = boxes.length - 1;
                _mint(_receivers[i], newBoxId);
                emit BoxMinted(newBoxId, _receivers[i]);
            }
        }
    }

    function buyBox(uint256 _quantities) external noContract nonReentrant {
        uint256 currentTimestamp = block.timestamp;
        require(_quantities > 0, "Amount must be greater than 0");
        uint256 curentTotalBoughtBoxesByAddress = _quantities.add(
            addressToTotalBoughtBoxes[msg.sender]
        );
        require(boxPrice > 0, "Box price does not set yet");
        require(
            curentTotalBoughtBoxesByAddress <= maxAllocationPerWallet,
            "You have reached your allocation"
        );
        require(
            currentTimestamp >= startSaleBoxAt &&
                currentTimestamp <= endSaleBoxAt,
            "Buy box is not available at this time"
        );
        require(
            totalSoldBoxes.add(_quantities) <= totalSellingBoxes,
            "No more boxes available"
        );
        require(
            IERC20(tokenContractAddress).transferFrom(
                msg.sender,
                address(this),
                boxPrice.mul(_quantities)
            ),
            "Token transfer failed"
        );
        addressToTotalBoughtBoxes[msg.sender] = _quantities.add(
            addressToTotalBoughtBoxes[msg.sender]
        );
        totalSoldBoxes += _quantities;
        for (uint256 i = 0; i < _quantities; i++) {
            Box memory newBox = Box(block.number, block.timestamp, true);
            boxes.push(newBox);
            uint256 newBoxId = boxes.length - 1;
            _mint(msg.sender, newBoxId);
            emit BoxMinted(newBoxId, msg.sender);
        }
    }

    function openBox(uint256 _boxId) external noContract {
        Box storage box = boxes[_boxId];
        require(
            ownerOf(_boxId) == msg.sender,
            "You are not the owner of this box"
        );
        require(box.isAvailable == true, "Box is not available");
        box.isAvailable = false;
        _burn(_boxId);
        (
            uint256 dinoGenes1,
            uint256 dinoGenes2,
            uint256 dinoGenes3,
            uint256 dinoGenes4,
            uint256 dinoGenes5
        ) = IFlashSaleManager(flashSaleBoxManagerAddress)
                .calculateRewards(_boxId, box.createdAtBlock);
        /// @dev Reward Dino
        uint256 dinoId1 = 0;
        uint256 dinoId2 = 0;
        uint256 dinoId3 = 0;
        uint256 dinoId4 = 0;
        uint256 dinoId5 = 0;
        uint128 dinoGender;
        if (dinoGenes1 > 0) {
            dinoGender = uint128((block.timestamp % 2) + 1);
            dinoId1 = _transferDinoReward(dinoGenes1, dinoGender, msg.sender);
        }
        if (dinoGenes2 > 0) {
            dinoGender = uint128(
                ((block.timestamp + dinoId1 + block.number) % 2) + 1
            );
            dinoId2 = _transferDinoReward(dinoGenes2, dinoGender, msg.sender);
        }
        if (dinoGenes3 > 0) {
            dinoGender = uint128(
                ((block.timestamp + dinoId2 + block.number) % 2) + 1
            );
            dinoId3 = _transferDinoReward(dinoGenes3, dinoGender, msg.sender);
        }
        if (dinoGenes4 > 0) {
            dinoGender = uint128(
                ((block.timestamp + dinoId3 + block.number) % 2) + 1
            );
            dinoId4 = _transferDinoReward(dinoGenes4, dinoGender, msg.sender);
        }
        if (dinoGenes5 > 0) {
            dinoGender = uint128(
                ((block.timestamp + dinoId4 + block.number) % 2) + 1
            );
            dinoId5 = _transferDinoReward(dinoGenes5, dinoGender, msg.sender);
        }
   
        emit BoxOpened(_boxId, msg.sender, dinoId1, dinoId2, dinoId3, dinoId4, dinoId5);
    }
}