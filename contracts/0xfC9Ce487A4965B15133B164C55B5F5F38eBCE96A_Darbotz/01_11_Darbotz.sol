// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./ERC721ACustom.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Darbotz is ERC721A, Pausable, ReentrancyGuard, Ownable {
    using Strings for uint256;
    bytes32 public ogMerkleRoot;
    bytes32 public wlMerkleRoot;
    bytes32 public teamMerkleRoot;
    bytes32 public team2MerkleRoot;

    IERC721 public token1;
    string public baseURI;
    address public treasury;
    mapping(address => walletMintData) public addressTokenMintData;
    mapping(address => bool) public adminAddresses;
    mapping(address => uint256) public teamMintsClaimed;

    modifier onlyAdminOrOwner() {
        bool isAdmin = false;
        if (adminAddresses[msg.sender] == true) {
            isAdmin = true;
        }
        if (msg.sender == owner()) {
            isAdmin = true;
        }
        require(isAdmin == true, "Not an admin");
        _;
    }

    struct SaleConfig {
        bool sale;
        bool dtcPhase;
        uint256 teamPrice;
        uint256 ogPrice;
        uint256 whitelistPrice;
        uint256 price;
        uint256 maxSupply;
        uint256 publicReserve;
        uint256 maxPublicMint;
        uint256 publicSupply;
    }
    SaleConfig public saleConfig;

    struct walletMintData {
        uint256 team;
        uint256 free;
        uint256 og;
        uint256 whitelist;
        uint256 publ;
        uint256 maxFreeMint;
        uint256 maxTeamMint;
        uint256 maxOGMint;
        uint256 maxWhitelistMint;
        uint256 maxPublicMint;
        bool maxMintsUpdated;
    }

    constructor(
        IERC721 _token1,
        uint256 _maxSupply,
        uint256 _publicReserve,
        uint256 _publicSupply,
        uint256 _maxPublicMint,
        bool _sale,
        bool _dtcPhase,
        bytes32 _teamMerkleRoot,
        bytes32 _ogMerkleRoot,
        bytes32 _wlMerkleRoot,
        bytes32 _team2MerkleRoot,
        address _treasury
    ) payable ERC721A("Darbotz", "DARBOTZ") {
        token1 = IERC721(_token1);
        saleConfig.maxSupply = _maxSupply;
        saleConfig.price = 0.069 ether;
        saleConfig.ogPrice = 0.0621 ether;
        saleConfig.whitelistPrice = 0.0655 ether;
        saleConfig.teamPrice = 0 ether;
        saleConfig.sale = _sale;
        saleConfig.dtcPhase = _dtcPhase;
        saleConfig.maxPublicMint = _maxPublicMint;
        saleConfig.publicReserve = _publicReserve;
        saleConfig.publicSupply = _publicSupply;
        teamMerkleRoot = _teamMerkleRoot;
        team2MerkleRoot = _team2MerkleRoot;
        ogMerkleRoot = _ogMerkleRoot;
        wlMerkleRoot = _wlMerkleRoot;
        treasury = _treasury;
        _safeMint(treasury, 140);
    }

    function dtcMint(uint256 _amount, bytes32[] calldata _merkleProof)
        public
        payable
        nonReentrant
        whenNotPaused
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        SaleConfig memory _saleConfig = saleConfig;
        uint256 _totalPrice;
        uint256 _mints;
        uint256 _maxSupply = saleConfig.maxSupply;
        uint256 _publicSupply = saleConfig.publicSupply;
        uint256 _token1Amount = token1.balanceOf(msg.sender);
        bool _isTeam = MerkleProof.verify(_merkleProof, teamMerkleRoot, leaf);
        bool _isOG = MerkleProof.verify(_merkleProof, ogMerkleRoot, leaf);
        bool _isWhitelist = MerkleProof.verify(
            _merkleProof,
            wlMerkleRoot,
            leaf
        );
        require(saleConfig.sale == true, "Minting has not sarted yet");
        require(isDTC(msg.sender, _merkleProof) == true, "Not part of DTC");
        require(saleConfig.dtcPhase == true, "DTC sale not live");
        require(
            totalSupply() + _amount <= saleConfig.maxSupply,
            "Cannot mint more than max supply"
        );
        require(
            tx.origin == msg.sender,
            "Cannot mint through a custom contract"
        );
        require(_amount > 0, "Negative values not allowed");
        if (addressTokenMintData[msg.sender].maxMintsUpdated == false) {
            if (_token1Amount > 0) {
                for (uint256 i = 0; i < _token1Amount; i++) {
                    addressTokenMintData[msg.sender].maxOGMint += 3;
                    addressTokenMintData[msg.sender].maxWhitelistMint += 2;
                }
            }
            if (_isOG == true && _token1Amount == 0) {
                addressTokenMintData[msg.sender].maxOGMint += 3;
            }
            if (_isWhitelist == true && _token1Amount == 0) {
                addressTokenMintData[msg.sender].maxWhitelistMint += 2;
            }
            addressTokenMintData[msg.sender].maxMintsUpdated = true;
        }
        while (_mints < _amount) {
            if (_mints + totalSupply() == _maxSupply) {
                break;
            } else if (
                _isTeam == true &&
                addressTokenMintData[msg.sender].team <
                addressTokenMintData[msg.sender].maxTeamMint
            ) {
                unchecked {
                    addressTokenMintData[msg.sender].team++;
                    addressTokenMintData[msg.sender].free++;
                    _mints++;
                }
            } else if (
                _token1Amount > 0 &&
                addressTokenMintData[msg.sender].og <
                addressTokenMintData[msg.sender].maxOGMint
            ) {
                _totalPrice += _saleConfig.ogPrice;
                unchecked {
                    addressTokenMintData[msg.sender].og++;
                    _mints++;
                }
            } else if (
                _token1Amount > 0 &&
                addressTokenMintData[msg.sender].whitelist <
                addressTokenMintData[msg.sender].maxWhitelistMint
            ) {
                require(
                    _publicSupply < saleConfig.publicReserve,
                    "Public Supply Over Allocated"
                );
                _totalPrice += _saleConfig.whitelistPrice;
                unchecked {
                    addressTokenMintData[msg.sender].whitelist++;
                    _mints++;
                    _publicSupply++;
                }
            } else if (
                _isOG == true &&
                addressTokenMintData[msg.sender].og <
                addressTokenMintData[msg.sender].maxOGMint
            ) {
                _totalPrice += _saleConfig.ogPrice;
                unchecked {
                    addressTokenMintData[msg.sender].og++;
                    _mints++;
                }
            } else if (
                _isWhitelist == true &&
                addressTokenMintData[msg.sender].whitelist <
                addressTokenMintData[msg.sender].maxWhitelistMint
            ) {
                require(
                    _publicSupply < saleConfig.publicReserve,
                    "Public Supply Over Allocated"
                );
                _totalPrice += _saleConfig.whitelistPrice;
                unchecked {
                    addressTokenMintData[msg.sender].whitelist++;
                    _mints++;
                    _publicSupply++;
                }
            } else if (
                addressTokenMintData[msg.sender].publ < saleConfig.maxPublicMint
            ) {
                require(
                    _publicSupply < saleConfig.publicReserve,
                    "Public Supply Over Allocated"
                );
                _totalPrice += _saleConfig.price;
                unchecked {
                    addressTokenMintData[msg.sender].publ++;
                    _mints++;
                    _publicSupply++;
                }
            }
        }
        require(msg.value >= _totalPrice, "insufficient funds");
        payable(treasury).transfer(msg.value);
        saleConfig.publicSupply = _publicSupply;
        _safeMint(msg.sender, _amount);
    }

    function mint(uint256 _amount) external payable nonReentrant whenNotPaused {
        require(saleConfig.dtcPhase == false, "Public mint not started");
        require(
            totalSupply() + _amount <= saleConfig.maxSupply,
            "Cannot mint more than max supply"
        );
        require(
            msg.value >= (saleConfig.price * _amount),
            "Insufficient funds"
        );
        require(
            addressTokenMintData[msg.sender].publ + _amount <=
                saleConfig.maxPublicMint,
            "Cannot mint more than 20 public per address"
        );
        payable(treasury).transfer(msg.value);
        unchecked {
            addressTokenMintData[msg.sender].publ += _amount;
        }
        _safeMint(msg.sender, _amount);
    }

    function teamMint(uint32 _amount, bytes32[] calldata _merkleProof)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            totalSupply() + _amount <= saleConfig.maxSupply,
            "Cannot mint more than max supply"
        );
        require(
            MerkleProof.verify(_merkleProof, team2MerkleRoot, leaf) == true,
            "Incorrect merkleProof"
        );
        require(
            addressTokenMintData[msg.sender].team <
                addressTokenMintData[msg.sender].maxTeamMint,
            "Max amount per wallet already minted"
        );
        addressTokenMintData[msg.sender].team += _amount;
        _safeMint(msg.sender, _amount);
    }

    function isDTC(address _wallet, bytes32[] calldata _merkleProof)
        public
        view
        returns (bool result)
    {
        bytes32 leaf = keccak256(abi.encodePacked(_wallet));
        bool _isTeam = MerkleProof.verify(_merkleProof, teamMerkleRoot, leaf);
        bool _isOG = MerkleProof.verify(_merkleProof, ogMerkleRoot, leaf);
        bool _isWhitelist = MerkleProof.verify(
            _merkleProof,
            wlMerkleRoot,
            leaf
        );
        if (
            _isTeam == true ||
            _isOG == true ||
            _isWhitelist == true ||
            token1.balanceOf(_wallet) > 0
        ) {
            return true;
        }
    }

    struct holderMaxMints {
        uint128 ogMints;
        uint256 wlMints;
    }

    function getHolderMaxMints(address _wallet)
        external
        view
        returns (holderMaxMints memory)
    {
        holderMaxMints memory _holderMaxMints;
        for (uint256 i = 0; i < token1.balanceOf(_wallet); i++) {
            _holderMaxMints.ogMints += 3;
            _holderMaxMints.wlMints += 2;
        }
        return _holderMaxMints;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistant token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
                : "";
    }

    struct tokens {
        uint256 token1;
    }

    function getTotalTokens(address _wallet)
        public
        view
        returns (tokens memory)
    {
        tokens memory _tokens;
        if (token1.balanceOf(_wallet) > 0) {
            _tokens.token1 = token1.balanceOf(_wallet);
        }
        return _tokens;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // ---------------------------------Admin functions-------------------------------------

    function setAdminAddresses(address[] calldata _wallets)
        external
        onlyAdminOrOwner
    {
        for (uint256 i = 0; i < _wallets.length; i++) {
            adminAddresses[_wallets[i]] = true;
        }
    }

    function removeAdminAddresses(address[] calldata _wallets)
        external
        onlyAdminOrOwner
    {
        for (uint256 i = 0; i < _wallets.length; i++) {
            adminAddresses[_wallets[i]] = false;
        }
    }

    function setBaseURI(string memory _newBaseURI) external onlyAdminOrOwner {
        baseURI = _newBaseURI;
    }

    function setPublicReserve(uint16 _newReserve) external onlyAdminOrOwner {
        require(
            _newReserve <= saleConfig.maxSupply,
            "Cannot set public reserve higher than max supply"
        );
        saleConfig.publicReserve = _newReserve;
    }

    function toggleSale() public onlyAdminOrOwner {
        saleConfig.sale = !saleConfig.sale;
    }

    function burnToken(uint256 _tokenId) external onlyAdminOrOwner {
        address owner = ERC721A.ownerOf(_tokenId);
        require(owner == msg.sender, "Not the owner of this token");
        super._burn(_tokenId);
    }

    function pauseContract() public onlyAdminOrOwner {
        _pause();
    }

    function unpauseContract() public onlyAdminOrOwner {
        _unpause();
    }

    function releaseDTCReserve() external onlyAdminOrOwner {
        saleConfig.publicReserve = 3333;
        saleConfig.dtcPhase = false;
    }

    function setMaxSupply(uint256 _newMaxSupply) external onlyAdminOrOwner {
        saleConfig.maxSupply = _newMaxSupply;
    }

    function setTeamMerkleRoot(bytes32 _newTeamMerkleRoot)
        external
        onlyAdminOrOwner
    {
        teamMerkleRoot = _newTeamMerkleRoot;
    }

    function setTeam2MerkleRoot(bytes32 _newTeam2MerkleRoot)
        external
        onlyAdminOrOwner
    {
        team2MerkleRoot = _newTeam2MerkleRoot;
    }

    function setOGMerkleRoot(bytes32 _newOGMerkleRoot)
        external
        onlyAdminOrOwner
    {
        ogMerkleRoot = _newOGMerkleRoot;
    }

    function setWhitelistMerkleRoot(bytes32 _newWhitelistMerkleRoot)
        external
        onlyAdminOrOwner
    {
        wlMerkleRoot = _newWhitelistMerkleRoot;
    }

    function setTreasuryAddress(address _treasury) external onlyAdminOrOwner {
        treasury = _treasury;
    }

    function setTeamMaxFreeMints(
        address[] calldata _wallets,
        uint8[] calldata _maxFreeMints
    ) external onlyAdminOrOwner {
        require(
            _wallets.length == _maxFreeMints.length,
            "Unmatching array lengths"
        );
        for (uint256 i = 0; i < _wallets.length; i++) {
            addressTokenMintData[_wallets[i]].maxTeamMint = _maxFreeMints[i];
        }
    }
}