// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721A.sol";

import "./interfaces/IAlphaGangGenerative.sol";

contract AlphaGangGenerative is ERC721A, Ownable {
    string public baseURI;

    uint256 public constant PRICE_WHALE = 49000000000000000; // 0.049 ether
    uint256 public constant PRICE = 69000000000000000; // 0.069 ether

    uint256 public price = PRICE; // 0.069 ether

    uint256 public constant SUPPLY = 5555;
    uint256 public maxSupply = 5777;

    address communityWallet = 0x08180E4DE9746BC1b3402aDd7fd0E61C9C100881;
    address payWallet = 0x08180E4DE9746BC1b3402aDd7fd0E61C9C100881;

    // Phase 1: Only WL and OG, Supply 999
    // Phase 2: Only WL and OG, Supply 1999
    // Phase 3: All, Supply 2555
    uint8 public mintPhase;

    mapping(address => uint256) public walletMints;

    bool public revealed;

    bytes32 whiteListMerkleI;
    bytes32 whiteListMerkleII;

    bytes32 waitListMerkle;

    constructor(
        string memory _initBaseURI,
        bytes32 _wlMRI,
        bytes32 _wlMRII,
        bytes32 _w8lMR
    ) ERC721A("Alpha Gang Generative", "AGG") {
        baseURI = _initBaseURI;
        whiteListMerkleI = _wlMRI;
        whiteListMerkleII = _wlMRII;
        waitListMerkle = _w8lMR;

        _safeMint(address(this), 1);
    }

    modifier mintCompliance(uint256 _mintAmount, uint8 mintType) {
        require(msg.sender == tx.origin, "EOA only");
        require((totalSupply() + _mintAmount) <= SUPPLY, "Max supply exceeded");
        require(mintActive(mintType), "Sale is not active");
        _;
    }

    function mintActive(uint8 mintType) public view returns (bool active) {
        uint256 _totalSupplyG2 = totalSupply();
        // Note this will allow for last mint to go over allocation
        if (mintPhase == 1) return mintType == 1 && _totalSupplyG2 < 1000;
        if (mintPhase == 2) return mintType == 1 && _totalSupplyG2 < 3000;
        if (mintPhase == 3) return mintType > 0;
        if (mintPhase == 4) return true;
        return false;
    }

    function ogMint(uint256 _mintAmount, uint256 _stakeCount)
        external
        payable
        mintCompliance(_mintAmount, 1)
    {
        address _owner = msg.sender;
        uint256 allocation = AGStake.ogAllocation(_owner);
        uint256 _walletMints = walletMints[msg.sender];
        require(allocation > _walletMints, "No allocation");

        if (_mintAmount > allocation - _walletMints) {
            _mintAmount = allocation - _walletMints;
        }

        // get the price, whales get discount
        uint256 _price = allocation > 4 ? PRICE_WHALE : PRICE;

        require(msg.value >= allocation * _price, "Insufficient funds!");

        uint256 firstTokenId = _nextTokenId();

        walletMints[msg.sender] += _mintAmount;

        _mint(_owner, _mintAmount);

        // if _stake is selected
        if (_stakeCount > 0) {
            unchecked {
                uint256[] memory _tokensToStake = new uint256[](_mintAmount);

                for (uint256 i = 0; i < _stakeCount; i++) {
                    _tokensToStake[i] = firstTokenId + i;
                }
                AGStake.stakeG2(_tokensToStake);
            }
        }
    }

    /**
     * @dev Function for white-listed members to mint a token
     *
     * Note having 2 separate functions will increase deployment cost but marginaly decrease minting cost
     */
    function mintWhiteListI(bytes32[] calldata _merkleProof, bool _stake)
        external
        payable
        mintCompliance(1, 1)
    {
        require(msg.value >= price, "Insufficient funds!");
        require(walletMints[msg.sender] < 2, "One pass per wallet");
        require(
            MerkleProof.verify(
                _merkleProof,
                whiteListMerkleI,
                keccak256(abi.encodePacked(msg.sender)) // leaf
            ),
            "Invalid Merkle Proof."
        );
        walletMints[msg.sender]++;
        _mint(msg.sender, 1);

        // if mint and stake call {stake} on {AGStakeFull}
        if (_stake) {
            uint256[] memory _tokensToStake = new uint256[](1);
            _tokensToStake[0] = _nextTokenId() - 1;
            AGStake.stakeG2(_tokensToStake);
        }
    }

    /**
     * @dev Function for white-listed members to mint two tokens
     *
     */
    function mintWhiteListII(bytes32[] calldata _merkleProof, bool _stake)
        external
        payable
        mintCompliance(2, 1)
    {
        require(msg.value >= price * 2, "Insufficient funds!");
        require(walletMints[msg.sender] < 1, "One pass per wallet");
        require(
            MerkleProof.verify(
                _merkleProof,
                whiteListMerkleII,
                keccak256(abi.encodePacked(msg.sender)) // leaf
            ),
            "Invalid Merkle Proof."
        );
        walletMints[msg.sender]++;
        _mint(msg.sender, 2);

        // if mint and stake call {stake} on {AGStakeFull}
        if (_stake) {
            uint256[] memory _tokensToStake = new uint256[](1);
            _tokensToStake[0] = _nextTokenId() - 1;
            _tokensToStake[0] = _nextTokenId() - 2;
            AGStake.stakeG2(_tokensToStake);
        }
    }

    /**
     * @dev Function for wait-listed members to mint a token
     *
     */
    function mintWaitList(bytes32[] calldata _merkleProof, bool _stake)
        external
        payable
        mintCompliance(1, 2)
    {
        require(msg.value >= price, "Insufficient funds!");
        require(walletMints[msg.sender] < 2, "One pass per wallet");
        require(
            MerkleProof.verify(
                _merkleProof,
                waitListMerkle,
                keccak256(abi.encodePacked(msg.sender)) // leaf
            ),
            "Invalid Merkle Proof."
        );
        walletMints[msg.sender]++;
        _mint(msg.sender, 1);

        // if mint and stake call {stake} on {AGStakeFull}
        if (_stake) {
            uint256[] memory _tokensToStake = new uint256[](1);
            _tokensToStake[0] = _nextTokenId() - 1;
            AGStake.stakeG2(_tokensToStake);
        }
    }

    function mintPublic(bool _stake) external payable mintCompliance(1, 0) {
        require(msg.value >= price, "Insufficient funds!");
        require(walletMints[msg.sender] < 2, "One pass per wallet");

        walletMints[msg.sender]++;
        _mint(msg.sender, 1);

        // if mint and stake call {stake} on {AGStakeFull}
        if (_stake) {
            uint256[] memory _tokensToStake = new uint256[](1);
            _tokensToStake[0] = _nextTokenId() - 1;
            AGStake.stakeG2(_tokensToStake);
        }
    }

    /**
     * @dev Minting for Community wallet and team
     *
     * This has additional 222 amount that it can tap into
     * Only for owners use
     */
    function mintForAddress(uint256 _mintAmount, address _receiver)
        public
        onlyOwner
    {
        require(
            (totalSupply() + _mintAmount) <= maxSupply,
            "Max reserves exhausted."
        );
        _mint(_receiver, _mintAmount);
    }

    function setRevealed() public onlyOwner {
        revealed = true;
    }

    /**
     * @dev sets a state of mint
     *
     * Requirements:
     *
     * - `_state` should be in: [0, 1, 2, 3, 4]
     * - 0 - mint not active, default
     * - 1 - sets mint to Phase 1
     * - 2 - sets mint to Phase 2
     * - 3 - sets mint to Phase 3
     * - 4 - sets mint to Public Mint
     * - mint is not active by default
     */
    function setSale(uint8 _state) public onlyOwner {
        mintPhase = _state;
    }

    /**
     * @dev Sets a Merkle proof() for a sale
     *
     * Requirements:
     *
     * - `_saleId` must be in: [0, 1, 2]
     * - 0 - sets a proof for { mintWhiteListI }
     * - 1 - sets a proof for { mintWhiteListII }
     * - 2 - sets a proof for { mintWaitList }
     * - `_state` bool value
     */
    function setMerkle(uint256 _saleId, bytes32 _merkleRoot) public onlyOwner {
        if (_saleId == 0) {
            whiteListMerkleI = _merkleRoot;
        }
        if (_saleId == 1) {
            whiteListMerkleII = _merkleRoot;
        }
        if (_saleId == 2) {
            waitListMerkle = _merkleRoot;
        }
    }

    // owner wallet(55%), community wallet(45%)
    function withdraw() public onlyOwner {
        (bool hs, ) = payable(payWallet).call{
            value: (address(this).balance * 45) / 100
        }("");
        require(hs);

        (bool os, ) = payable(communityWallet).call{
            value: (address(this).balance * 55) / 100
        }("");
        require(os);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (!revealed) return _baseURI();
        return super.tokenURI(_tokenId);
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory ownerTokens)
    {
        uint256 supply = totalSupply();
        uint256 _ownerTokenCount = balanceOf(_owner);
        uint256[] memory _ownerTokens = new uint256[](_ownerTokenCount);
        unchecked {
            uint256 index;
            for (uint256 tokenId = 1; tokenId <= supply; ++tokenId) {
                if (ownerOf(tokenId) == _owner) {
                    _ownerTokens[index] = tokenId;
                    ++index;
                }
            }
        }

        return _ownerTokens;
    }

    function setWallets(address _wallet, bool _payWallet) external onlyOwner {
        if (_payWallet) {
            payWallet = _wallet;
        } else {
            communityWallet = _wallet;
        }
    }

    /**
     * Sets the price for mint
     * To be used for Phase 3 of the mint
     */
    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    /**
     * Staking Contract addresse setter
     */
    function setAGStake(address _agStake) external onlyOwner {
        AGStake = IAGStake(_agStake);
    }
}