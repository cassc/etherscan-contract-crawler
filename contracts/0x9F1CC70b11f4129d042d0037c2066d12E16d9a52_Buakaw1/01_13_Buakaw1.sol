// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";

contract Buakaw1 is Ownable, ERC721A, ReentrancyGuard {
    event WhitelistMint(
        uint256 indexed roundIndex,
        uint256 indexed quantity,
        address indexed minter,
        uint256 totalMinted
    );
    event WithdrawMoney(
        uint256 indexed blocktime,
        uint256 indexed amount,
        address indexed sender
    );

    uint256 public immutable amountForMarketing;
    uint256 public immutable collectionSize;
    address public immutable vaultAddress;
    address public immutable preMinteeAddress;

    //1:founding round
    //2:six flavor round
    //3:partner round
    //4:public round
    struct SaleConfig {
        uint32 roundSaleStartTime;
        uint32 roundSaleEndTime;
        uint64 roundPrice;
        string roundSaleKey;
        uint256 summaryRoundSale;
        uint32 maxPerAddressDuringMint;
        uint32 maxPerRound;
        bytes32 merkleRoot;
    }

    SaleConfig[4] public saleConfigs;

    constructor(
        uint256 collectionSize_,
        uint256 amountForMarketing_,
        address vaultAddress_,
        address preMinteeAddress_
    ) ERC721A("Buakaw1", "BK1") {
        require(collectionSize_ > 0, "collection must have a nonzero supply");
        amountForMarketing = amountForMarketing_;
        collectionSize = collectionSize_;
        vaultAddress = vaultAddress_;
        preMinteeAddress = preMinteeAddress_;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function _isEqual(string memory s1, string memory s2)
        internal
        pure
        returns (bool)
    {
        return
            keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }

    function setSaleConfig(
        uint32 _index,
        uint32 _roundSaleStartTime,
        uint32 _roundSaleEndTime,
        uint64 _roundPrice,
        uint32 _maxPerAddressDuringMint,
        uint32 _maxPerRound,
        bytes32 _merkleRoot
    ) external onlyOwner {
        require(
            _roundSaleStartTime >= block.timestamp &&
                _roundSaleEndTime >= block.timestamp,
            "Invalid round start and end time"
        );
        require(
            _maxPerAddressDuringMint > 0,
            "max per address must be nonzero"
        );
        require(_roundPrice >= 0, "Round price must be nonzero");
        require(_merkleRoot != "", "Merkle Root should not be empty");

        saleConfigs[_index] = SaleConfig(
            _roundSaleStartTime,
            _roundSaleEndTime,
            _roundPrice,
            "",
            0,
            _maxPerAddressDuringMint,
            _maxPerRound,
            _merkleRoot
        );
    }

    function setRoundSaleKey(uint256 index, string memory key)
        external
        onlyOwner
    {
        saleConfigs[index].roundSaleKey = key;
    }

    function getRoundSaleconfig(uint256 roundIndex)
        external
        view
        returns (SaleConfig memory)
    {
        return saleConfigs[roundIndex];
    }

    //Mint Round
    mapping(address => uint256) public foundingMinterAllocate;
    mapping(address => uint256) public favourMinterAllocate;
    mapping(address => uint256) public whitelistMinterAllocate;
    mapping(address => uint256) public publicMinterAllocate;

    function setMinterAllocate(
        uint256 roundIndex,
        uint256 quantity,
        address minter
    ) internal {
        if (roundIndex == 0) {
            foundingMinterAllocate[minter] += quantity;
        } else if (roundIndex == 1) {
            favourMinterAllocate[minter] += quantity;
        } else if (roundIndex == 2) {
            whitelistMinterAllocate[minter] += quantity;
        } else if (roundIndex == 3) {
            publicMinterAllocate[minter] += quantity;
        }
    }

    function getMinterAllocate(uint256 roundIndex, address minter)
        internal
        view
        returns (uint256 allocate)
    {
        if (roundIndex == 0) {
            allocate = foundingMinterAllocate[minter];
        } else if (roundIndex == 1) {
            allocate = favourMinterAllocate[minter];
        } else if (roundIndex == 2) {
            allocate = whitelistMinterAllocate[minter];
        } else if (roundIndex == 3) {
            allocate = publicMinterAllocate[minter];
        }
    }

    function preMint(uint256 quantity) external onlyOwner {
        require(
            totalSupply() + quantity <= amountForMarketing,
            "Too many already minted"
        );
        _safeMint(preMinteeAddress, quantity);
    }

    function whitelistMint(
        uint256 roundIndex,
        uint256 quantity,
        bytes32[] calldata _merkleProof,
        string memory whitelistSaleKey
    ) external payable callerIsUser {
        require(roundIndex >= 0 && roundIndex < 3, "0:Invalid round");
        //get round config
        SaleConfig memory config = saleConfigs[roundIndex];
        string memory roundSaleKey = config.roundSaleKey;
        uint256 roundPrice = uint256(config.roundPrice);
        uint256 roundSaleStartTime = uint256(config.roundSaleStartTime);
        uint256 roundSaleEndTime = uint256(config.roundSaleEndTime);
        uint256 maxPerAddressDuringMint = uint256(
            config.maxPerAddressDuringMint
        );
        uint256 maxPerDurringRound = uint256(config.maxPerRound);
        uint256 summaryRoundSale = config.summaryRoundSale;
        bytes32 root = config.merkleRoot;

        require(
            isRoundSaleOn(
                roundPrice,
                roundSaleStartTime,
                roundSaleEndTime,
                roundSaleKey
            ),
            "1:Mint is not live"
        );
        require(
            _isEqual(whitelistSaleKey, roundSaleKey),
            "2:Called with incorrect mint key"
        );
        require(quantity > 0, "3:quantity must not be zero");
        require(
            totalSupply() + quantity <= collectionSize,
            "4:Reached max supply"
        );
        require(
            summaryRoundSale + quantity <= maxPerDurringRound,
            "5:Reached max for this round"
        );

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, root, leaf),
            "6:MerkleProof: Verify fail"
        );

        {
            uint256 index = roundIndex;
            uint256 amount = quantity;
            uint256 minterAllocate = getMinterAllocate(index, msg.sender);

            require(
                amount <= maxPerAddressDuringMint - minterAllocate,
                "7:Can not mint this many"
            );
            setMinterAllocate(index, amount, msg.sender);
            _safeMint(msg.sender, amount);

            //total sale per round
            saleConfigs[index].summaryRoundSale += amount;

            refundIfOver(roundPrice * amount);
            emit WhitelistMint(index, amount, msg.sender, totalSupply());
        }
    }

    function publicMint(
        uint256 roundIndex,
        uint256 quantity,
        string memory callerRoundSaleKey
    ) external payable {
        require(roundIndex == 3, "0:Invalid round");
        SaleConfig memory config = saleConfigs[roundIndex];
        string memory roundSaleKey = config.roundSaleKey;
        uint256 roundPrice = uint256(config.roundPrice);
        uint256 roundSaleStartTime = uint256(config.roundSaleStartTime);
        uint256 maxPerAddressDuringMint = uint256(
            config.maxPerAddressDuringMint
        );
        require(
            block.timestamp >= roundSaleStartTime,
            "8:Sale has not begun yet"
        );
        require(
            _isEqual(callerRoundSaleKey, roundSaleKey) &&
                !_isEqual(roundSaleKey, ""),
            "2:Called with incorrect mint key"
        );
        require(quantity > 0, "3:quantity must not be zero");
        require(
            totalSupply() + quantity <= collectionSize,
            "4:Reached max supply"
        );

        uint256 minterAllocate = getMinterAllocate(roundIndex, msg.sender);
        require(
            quantity <= maxPerAddressDuringMint - minterAllocate,
            "7:Can not mint this many"
        );
        setMinterAllocate(roundIndex, quantity, msg.sender);
        _safeMint(msg.sender, quantity);
        saleConfigs[roundIndex].summaryRoundSale += quantity;
        refundIfOver(roundPrice * quantity);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function isRoundSaleOn(
        uint256 roundPriceWei,
        uint256 roundSaleStartTime,
        uint256 roundSaleEndTime,
        string memory roundSaleKey
    ) public view returns (bool) {
        return
            roundPriceWei != 0 &&
            block.timestamp >= roundSaleStartTime &&
            block.timestamp <= roundSaleEndTime &&
            !_isEqual(roundSaleKey, "");
    }

    // // metadata URI
    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawMoney() external nonReentrant {
        require(msg.sender == vaultAddress, "Invalid Address");
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
        emit WithdrawMoney(block.timestamp, address(this).balance, msg.sender);
    }

    function numberMinted(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return _ownershipOf(tokenId);
    }
}