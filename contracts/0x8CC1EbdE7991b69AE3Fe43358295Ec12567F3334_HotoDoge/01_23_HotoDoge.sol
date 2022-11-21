// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "ERC721Psi.sol";
import "Ownable.sol";
import "Base64.sol";
import "ReentrancyGuard.sol";
import "SafeMath.sol";
import "MerkleProof.sol";
import "IVRFGenerator.sol";
import "IDDS.sol";
import "IAccessories.sol";

contract HotoDoge is ERC721Psi, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    struct Publish {
        uint8 winner;
        address operator;
        bool published;
    }

    uint256 public constant MAX_SUPPLY = 9600;
    uint256 public constant FAR_FUTURE = type(uint256).max;

    uint256 public _whiteListSalesStart = FAR_FUTURE;
    uint256 public _publicSaleStart = FAR_FUTURE;
    uint256 public _showTimeStart = FAR_FUTURE;
    string _baseTokenURI;

    uint256 private _mintPrice;
    uint16 private _share;
    bytes32 private _merkleRoot;

    mapping(uint8 => Publish) publish;
    uint16[] nfts;
    mapping(uint16 => uint8) airDrops;
    uint16[] finalWinners;
    uint16 winner1 = type(uint16).max;
    uint16 winner2 = type(uint16).max;
    mapping(uint16 => bool) cashReady;
    bool[2] bigWinnerReady;

    mapping(address => bool) operators;
    mapping(address => uint8) whiteListSales;
    IAccessories aces;
    IVRFGenerator vrf;
    uint256 _vrfRequestId;
    uint256 pool; // money to share for every one

    uint256 preCash;

    event whiteListSalesStart(uint256 time);
    event whiteListSalesPaused(uint256 time);
    event publicSaleStart(uint256 time);
    event publicSalePaused(uint256 time);
    event baseUIRChanged(string uri);
    event showTimeNotStart(uint256 time);
    event showTimeStart(uint256 time);
    event airDropped(address to, uint256 tokenId, uint8 amount);
    event cashedOut(address to, uint256 tokenId, uint256 amount);
    event winnerReleased(uint16 id, address currentOwner);

    modifier onlyEOA() {
        if (tx.origin != msg.sender)
            revert("Only Externally Owned Accounts Allowed");
        _;
    }

    modifier onlyOperator() {
        if (!operators[tx.origin] && msg.sender != owner())
            revert("Only Operator Accounts Allowed");
        _;
    }

    constructor(
        string memory baseURI,
        uint256 mint_price,
        uint16 share,
        bytes32 root
    ) ERC721Psi("HotoDoge", "HTD") {
        require(share >= 0 && share <= 1000, "share must between 0 and 1000");

        _baseTokenURI = baseURI;
        _mintPrice = mint_price;
        _share = share;
        _merkleRoot = root;

        vrf = IVRFGenerator(
            IDDS(BEE_DDS_ADDRESS).toAddress(
                IDDS(BEE_DDS_ADDRESS).get("ISOTOP", "BEE_VRF_ADDRESS")
            )
        );

        aces = IAccessories(
            IDDS(BEE_DDS_ADDRESS).toAddress(
                IDDS(BEE_DDS_ADDRESS).get("ISOTOP", "BEE_HOTO_PROP_ADDRESS")
            )
        );
    }

    // publicSale
    function isWhiteListSaleActive() public view returns (bool) {
        return block.timestamp >= _whiteListSalesStart;
    }

    function isPublicSaleActive() public view returns (bool) {
        return block.timestamp >= _publicSaleStart;
    }

    function isShowTimeStart() public view returns (bool) {
        return block.timestamp >= _showTimeStart;
    }

    function getAirDrops(uint256 tokenId) external view returns (uint8) {
        require(_exists(tokenId), "token not exists");
        return airDrops[uint16(tokenId)];
    }

    function claimAirDrops(uint256 tokenId) external onlyEOA nonReentrant {
        require(ownerOf(tokenId) == msg.sender, "Only owner");
        uint8 value = airDrops[uint16(tokenId)];

        if (value == 0) revert("no airdrops found");

        // airdrop to msg.sender
        aces.mint(msg.sender, value);

        airDrops[uint16(tokenId)] = 0;
        emit airDropped(msg.sender, tokenId, value);
    }

    function getCash(uint256 tokenId) external view returns (uint256 _cash) {
        require(publish[64].published, "Final winner not released");

        if (!cashReady[uint16(tokenId)]) return 0;
        // Do the math
        uint256 count = finalWinners.length;

        // Do the math
        for (uint256 i = 0; i < count; i++)
            if (finalWinners[i] == tokenId) {
                _cash += pool.mul(35).div(100).div(count);
                break;
            }
    }

    function claimCash(uint256 tokenId) external onlyEOA nonReentrant {
        require(ownerOf(tokenId) == msg.sender, "Only owner");
        require(publish[64].published, "Final winner not released");

        if (!cashReady[uint16(tokenId)]) revert("no fund or cashed out");

        uint256 _cash = 0;
        uint256 count = finalWinners.length;

        // Do the math
        for (uint256 i = 0; i < count; i++)
            if (finalWinners[i] == tokenId) {
                _cash += pool.mul(35).div(100).div(count);
                break;
            }

        // payable(msg.sender).transfer(_cash);
        (bool success, ) = msg.sender.call{value: _cash}("");
        require(success, "Claim transfer failed");

        cashReady[uint16(tokenId)] = false;
        emit cashedOut(msg.sender, tokenId, _cash);
    }

    function getBigWinnerCash(uint256 tokenId)
        external
        view
        returns (uint256 _cash)
    {
        require(publish[64].published, "Final winner not released");

        if (tokenId == winner1)
            if (bigWinnerReady[0])
                // you lucky buster
                _cash += pool.mul(35).div(100).div(2);

        if (tokenId == winner2)
            if (bigWinnerReady[1])
                // you lucky buster two
                _cash += pool.mul(35).div(100).div(2);
    }

    function claimBigWinnerCash(uint256 tokenId) external onlyEOA nonReentrant {
        require(ownerOf(tokenId) == msg.sender, "Only owner");
        require(publish[64].published, "Final winner not released");

        uint256 _cash = 0;

        if (tokenId == winner1) {
            if (!bigWinnerReady[0]) revert("no fund or cashed out");
            // you lucky buster
            _cash += pool.mul(35).div(100).div(2);
            bigWinnerReady[0] = false;
        }
        if (tokenId == winner2) {
            if (!bigWinnerReady[1]) revert("no fund or cashed out");
            // you lucky buster two
            _cash += pool.mul(35).div(100).div(2);
            bigWinnerReady[1] = false;
        }

        // payable(msg.sender).transfer(_cash);
        (bool success, ) = msg.sender.call{value: _cash}("");
        require(success, "Claim transfer failed");

        emit cashedOut(msg.sender, tokenId, _cash);
    }

    function getWhiteListMint(address _who) public view returns (uint8) {
        return whiteListSales[_who];
    }

    function whitelistMint(uint8 quantity)
        external
        payable
        onlyEOA
        nonReentrant
    {
        require(isWhiteListSaleActive(), "Whitelist Sales Not Started");
        require(!isShowTimeStart(), "Whitelist Sales Finished");
        require(
            whiteListSales[msg.sender] + quantity <= 3,
            "max 3 NFT allowed"
        );
        require(nfts.length + quantity <= MAX_SUPPLY, "max nft sold");

        IERC721 xt = IERC721(
            IDDS(BEE_DDS_ADDRESS).toAddress(
                IDDS(BEE_DDS_ADDRESS).get("ISOTOP", "BEE_XT_CONTRACT_ADDRESS")
            )
        );

        if (xt.balanceOf(msg.sender) == 0) revert("Not XT token owner");

        uint256 cost = _mintPrice.mul(6).div(10).mul(quantity);
        require(msg.value >= cost, "Insufficient Payment");
        pool += cost;

        _mint(msg.sender, quantity);
        for (uint8 i = 0; i < quantity; i++) nfts.push(0);

        // Refund overpayment
        if (msg.value > cost) {
            // payable(msg.sender).transfer(msg.value.sub(cost));
            (bool success, ) = msg.sender.call{value: msg.value.sub(cost)}("");
            require(success, "Public sales transfer failed");
        }

        whiteListSales[msg.sender] += quantity;
    }

    function whitelistMint(bytes32[] calldata _merkleProof, uint8 quantity)
        external
        payable
        onlyEOA
        nonReentrant
    {
        require(isWhiteListSaleActive(), "Whitelist Sales Not Started");
        require(!isShowTimeStart(), "Whitelist Sales Finished");
        require(
            whiteListSales[msg.sender] + quantity <= 3,
            "max 3 NFT allowed"
        );
        require(nfts.length + quantity <= MAX_SUPPLY, "max nft sold");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verify(_merkleProof, _merkleRoot, leaf))
            revert("Not in white list");

        uint256 cost = _mintPrice.mul(6).div(10).mul(quantity);
        require(msg.value >= cost, "Insufficient Payment");
        pool += cost;

        _mint(msg.sender, quantity);
        for (uint8 i = 0; i < quantity; i++) nfts.push(0);

        // Refund overpayment
        if (msg.value > cost) {
            // payable(msg.sender).transfer(msg.value.sub(cost));
            (bool success, ) = msg.sender.call{value: msg.value.sub(cost)}("");
            require(success, "Public sales transfer failed");
        }

        whiteListSales[msg.sender] += quantity;
    }

    function publicSaleMint(uint8 quantity)
        external
        payable
        onlyEOA
        nonReentrant
    {
        require(isPublicSaleActive(), "Public Sales Not Started");
        require(!isShowTimeStart(), "Public Sales Finished");
        require(
            balanceOf(msg.sender) + quantity <= 4 + whiteListSales[msg.sender],
            "max 4 public sales NFT allowed"
        );
        require(nfts.length + quantity <= MAX_SUPPLY, "max nft sold");

        uint256 cost = _mintPrice.mul(quantity);
        require(msg.value >= cost, "Insufficient Payment");
        pool += cost;

        _mint(msg.sender, quantity);
        for (uint8 i = 0; i < quantity; i++) nfts.push(0);

        // Refund overpayment
        if (msg.value > cost) {
            // payable(msg.sender).transfer(msg.value.sub(cost));
            (bool success, ) = msg.sender.call{value: msg.value.sub(cost)}("");
            require(success, "Public sales transfer failed");
        }
    }

    // METADATA

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokensOf(address owner)
        public
        view
        onlyEOA
        returns (uint256[] memory)
    {
        uint256 count = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](count);
        for (uint256 i; i < count; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }

    // DISPLAY

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "nonexistent token");

        if (!isShowTimeStart())
            return string(abi.encodePacked(_baseURI(), "cover.json"));
        else
            return
                string(
                    abi.encodePacked(
                        _baseURI(),
                        _toString(nfts[tokenId]),
                        ".json"
                    )
                );
    }

    function tokenInfo(uint256 tokenId)
        external
        view
        returns (uint256 _team, uint256 _no)
    {
        require(_exists(tokenId), "nonexistent token");
        uint16 value = nfts[tokenId];
        _team = value / 300;
        _no = value % 300;
    }

    function getRoundStatus(uint8 round)
        external
        view
        returns (Publish memory)
    {
        return publish[round];
    }

    function getFinalWinners() external view returns (uint16[] memory) {
        return finalWinners;
    }

    function getBigWinners() external view returns (uint16, uint16) {
        return (winner1, winner2);
    }

    // OPERATORS
    function setWinner(uint8 round, uint8 _team) external onlyOperator {
        require(round < 64, "max 64 matchs");
        if (publish[round].published) revert("this round had published");

        if (
            publish[round].operator == ZERO ||
            publish[round].operator == msg.sender
        ) {
            publish[round] = Publish(_team, msg.sender, false);
            return;
        }

        if (publish[round].winner != _team) {
            publish[round].operator = msg.sender;
            publish[round].winner = _team;
            return;
        }
        for (uint16 i = 0; i < nfts.length; i++)
            if (uint256(nfts[i] / 300) == _team) airDrops[i] += 1;

        publish[round].published = true;
    }

    function setFinalWinner(uint8 round, uint8 _team) external onlyOperator {
        require(round == 64, "final match must be 64 matchs");
        if (publish[round].published) revert("this round had published");

        if (
            publish[round].operator == ZERO ||
            publish[round].operator == msg.sender
        ) {
            publish[round] = Publish(_team, msg.sender, false);
            return;
        }

        if (publish[round].winner != _team) {
            publish[round].operator = msg.sender;
            publish[round].winner = _team;
            return;
        }

        for (uint16 i = 0; i < nfts.length; i++)
            if (uint256(nfts[i] / 300) == _team) {
                airDrops[i] += 1;
                finalWinners.push(i);
                cashReady[i] = true;
            }

        if (finalWinners.length == 0) {
            publish[round].published = true;
            return;
        }

        if (finalWinners.length == 1) {
            winner1 = finalWinners[0];
            winner2 = finalWinners[0];
        } else if (finalWinners.length == 2) {
            winner1 = finalWinners[0];
            winner2 = finalWinners[1];
        } else {
            uint256 _random = block.timestamp;

            if (_vrfRequestId != 0) {
                (bool fulfilled, uint256[] memory randomWords) = vrf
                    .getRequestStatus(_vrfRequestId);
                if (fulfilled) _random = randomWords[1];
            }

            uint16[] memory _winners = vrf.shuffle16(
                uint16(finalWinners.length),
                _random
            );

            winner1 = finalWinners[_winners[0]];
            winner2 = finalWinners[_winners[1]];
        }
        emit winnerReleased(winner1, ownerOf(winner1));
        emit winnerReleased(winner2, ownerOf(winner2));

        publish[round].published = true;
        bigWinnerReady[0] = true;
        bigWinnerReady[1] = true;
    }

    function startWhiteListSale() external onlyOperator {
        _whiteListSalesStart = block.timestamp;

        // We need 2 shuffle random seeds
        // 1: blind box
        // 2: final winner
        _vrfRequestId = vrf.requestRandomWords(2);

        emit whiteListSalesStart(block.timestamp);
    }

    function pauseWhiteListSale() external onlyOperator {
        _whiteListSalesStart = FAR_FUTURE;
        emit whiteListSalesPaused(block.timestamp);
    }

    function startPublicSale() external onlyOperator {
        _publicSaleStart = block.timestamp;

        emit publicSaleStart(block.timestamp);
    }

    function pausePublicSale() external onlyOperator {
        _publicSaleStart = FAR_FUTURE;
        emit publicSalePaused(block.timestamp);
    }

    function startShowTime() external onlyOperator {
        _showTimeStart = block.timestamp;
        uint256 _random = block.timestamp;

        if (_vrfRequestId != 0) {
            (bool fulfilled, uint256[] memory randomWords) = vrf
                .getRequestStatus(_vrfRequestId);
            if (fulfilled) _random = randomWords[0];
        }

        uint16[] memory shuffledId = vrf.shuffle16(9600, _random);

        for (uint256 i = 0; i < nfts.length; i++) nfts[i] = shuffledId[i];

        emit showTimeStart(block.timestamp);
    }

    // OWNERS + HELPERS

    function setOperators(address[] calldata _operators) external onlyOwner {
        for (uint256 i = 0; i < _operators.length; i++)
            operators[_operators[i]] = true;
    }

    function setURInew(string memory uri)
        external
        onlyOwner
        returns (string memory)
    {
        _baseTokenURI = uri;
        emit baseUIRChanged(uri);
        return _baseTokenURI;
    }

    function setRoot(bytes32 root) external onlyOwner {
        _merkleRoot = root;
    }

    // Team/Partnerships & Community
    function marketingMint(uint16 quantity) external onlyOwner {
        require(!isShowTimeStart(), "Sales Finished");
        require(nfts.length + quantity <= MAX_SUPPLY, "max nft sold");

        _safeMint(owner(), quantity);
        for (uint8 i = 0; i < quantity; i++) nfts.push(0);
    }

    function getPaycash() external view onlyOwner returns (uint256, uint256) {
        return (pool, preCash);
    }

    function withdraw() external onlyOwner returns (uint256) {
        uint256 total = pool.mul(30).div(100);
        if (total <= preCash) return 0;

        total -= preCash;

        uint256 split1 = total.mul(_share).div(1000);
        uint256 split2 = total - split1;

        (bool success1, ) = address(0x7B0dc23E87febF1D053E7Df9aF4cce30F21fAe9C)
            .call{value: split1}("");
        (bool success2, ) = address(0x9da32F03cc23F9156DaA7442cADbE8366ddAc123)
            .call{value: split2}("");
        require(success1 && success2, "withdraw transfer failed");

        preCash += total;
        return total;
    }

    function reset() external onlyOwner {
        selfdestruct(payable(0x7B0dc23E87febF1D053E7Df9aF4cce30F21fAe9C));
    }

    function config()
        external
        view
        onlyOwner
        returns (
            address,
            address,
            address
        )
    {
        return (address(BEE_DDS_ADDRESS), address(vrf), address(aces));
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value)
        internal
        pure
        virtual
        returns (string memory str)
    {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 0x80 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 0x20 + 3 * 0x20 = 0x80.
            str := add(mload(0x40), 0x80)
            // Update the free memory pointer to allocate.
            mstore(0x40, str)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }
}