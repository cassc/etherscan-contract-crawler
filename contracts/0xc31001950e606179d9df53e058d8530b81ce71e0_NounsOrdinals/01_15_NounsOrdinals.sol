// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import {ERC721AQueryable} from "ERC721A/extensions/ERC721AQueryable.sol";
import "ERC721A/ERC721A.sol";
import "./IERC4906.sol";
import "openzeppelin-contracts/contracts/access/AccessControl.sol";

enum TicketID {
    AllowList,
    FamilySale
}

error PreMaxExceed(uint256 _presaleMax);
error MaxSupplyOver();
error NotEnoughFunds(uint256 balance);
error NotMintable();
error InvalidMerkleProof();
error AlreadyClaimedMax();
error MintAmountOver();

contract NounsOrdinals is ERC721A, IERC4906, ERC721AQueryable, AccessControl {
    uint256 private constant _PUBLIC_MAX_PER_TX = 10;
    uint256 private constant _PRE_MAX_CAP = 100;
    string private constant _BASE_EXTENSION = ".json";
    address private constant _FUND_ADDRESS =
        0x16dCDAa58c119620Ca75547840c17eE4D9A9c2f9;
    address private constant _ADMIN_ADDRESS =
        0x9A02894330c5d520979f269C7D2b41e4B1e463B5;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    bool public publicSale = false;
    bool public callerIsUserFlg = false;
    bool public mintable = false;
    bool public operatorFilteringEnabled = true;
    bool public renounceOwnerMintFlag = false;

    uint256 public maxSupply = 750;
    uint256 public publicCost = 0.015 ether;
    string private _baseURL =
        "https://arweave.net/UdEfjkvETTZoLSFwrDyAvEl7_jSGHbMVObkXmCDiiGg/";

    mapping(address => bool) _unlockedAddress;
    mapping(address => string) public btcAddress;

    mapping(TicketID => bool) public presalePhase;
    mapping(TicketID => uint256) public presaleCost;
    mapping(TicketID => bytes32) public merkleRoot;
    mapping(uint256 => string) private _metadataURI;

    constructor() ERC721A("NounsOrdinals", "NOUNS") {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
        _mintERC2309(_ADMIN_ADDRESS, 50);
    }

    modifier whenMintable() {
        if (mintable == false) revert NotMintable();
        _;
    }

    /**
     * @dev The modifier allowing the function access only for real humans.
     */
    modifier callerIsUser() {
        if (callerIsUserFlg == true) {
            require(tx.origin == msg.sender, "The caller is another contract");
        }
        _;
    }

    // internal
    function _baseURI() internal view override returns (string memory) {
        return _baseURL;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        if (bytes(_metadataURI[tokenId]).length == 0) {
            return
                string(
                    abi.encodePacked(ERC721A.tokenURI(tokenId), _BASE_EXTENSION)
                );
        } else {
            return _metadataURI[tokenId];
        }
    }

    function setTokenMetadataURI(
        uint256 tokenId,
        string memory metadata
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _metadataURI[tokenId] = metadata;
        emit MetadataUpdate(tokenId);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 0;
    }

    /**
     * @notice 保有者のアドレスを受け取り、SBTにロックがかかっているかどうかを返します。
       @param to 保有者のアドレス
       @return もしロックされている場合は true を返却します
     */

    function bounded(address to) external view returns (bool) {
        return !_unlockedAddress[to];
    }

    /**
     * @notice 特定アドレスおとに、SBTのロックをするかどうかを指定します。
       @param to 保有者のアドレス
       @param flag もしロックしたい場合はtrue
       @dev MINTER_ROLE あ操作には必要です。
     */
    function bound(address to, bool flag) public onlyRole(MINTER_ROLE) {
        _unlockedAddress[to] = !flag;
    }

    /**
     * @notice Set the merkle root for the allow list mint
     */
    function setMerkleRoot(
        bytes32 _merkleRoot,
        TicketID ticket
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        merkleRoot[ticket] = _merkleRoot;
    }

    function setCallerIsUserFlg(
        bool flg
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        callerIsUserFlg = flg;
    }

    function publicMint(
        address _to,
        uint256 _mintAmount,
        string memory _btcAddress
    ) external payable callerIsUser whenMintable {
        if (_totalMinted() + _mintAmount > maxSupply) revert MaxSupplyOver();
        if (msg.value < publicCost * _mintAmount)
            revert NotEnoughFunds(msg.value);
        if (!publicSale) revert NotMintable();
        if (_mintAmount > _PUBLIC_MAX_PER_TX) revert MintAmountOver();

        btcAddress[msg.sender] = _btcAddress;
        _mint(_to, _mintAmount);
    }

    function preMint(
        uint256 _mintAmount,
        uint256 _presaleMax,
        bytes32[] calldata _merkleProof,
        TicketID ticket,
        string memory _btcAddress
    ) external payable whenMintable {
        if (_presaleMax > _PRE_MAX_CAP) revert PreMaxExceed(_presaleMax);
        if (_totalMinted() + _mintAmount > maxSupply) revert MaxSupplyOver();
        if (msg.value < presaleCost[ticket] * _mintAmount)
            revert NotEnoughFunds(msg.value);
        if (!presalePhase[ticket]) revert NotMintable();
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _presaleMax));
        uint64 claimed = getWhiteListClaimed(ticket, msg.sender) +
            uint64(_mintAmount);
        if (!MerkleProof.verifyCalldata(_merkleProof, merkleRoot[ticket], leaf))
            revert InvalidMerkleProof();
        if (claimed > _presaleMax) revert AlreadyClaimedMax();

        btcAddress[msg.sender] = _btcAddress;
        _setWhiteListClaimed(ticket, msg.sender, claimed);
        _mint(msg.sender, _mintAmount);
    }

    function _setWhiteListClaimed(
        TicketID ticket,
        address account,
        uint64 claimed
    ) internal {
        uint64 packedData = (claimed << 32) | uint64(ticket);
        _setAux(account, packedData);
    }

    function getWhiteListClaimed(
        TicketID ticket,
        address account
    ) public view returns (uint64) {
        uint64 packedData = _getAux(account);
        uint64 savedTicket = packedData & uint64((1 << 32) - 1);
        uint64 claimed = packedData >> 32;
        if (savedTicket != uint64(ticket)) {
            return 0;
        }
        return claimed;
    }

    function ownerMint(
        address _address,
        uint256 count
    ) external onlyRole(MINTER_ROLE) {
        require(!renounceOwnerMintFlag, "owner mint renounced");
        _safeMint(_address, count);
    }

    function setBTCAddress(
        address _address,
        string memory _btcAddress
    ) external onlyRole(MINTER_ROLE) {
        btcAddress[_address] = _btcAddress;
    }

    function tokenBTCAddress(
        uint256 _tokenId
    ) external view returns (string memory) {
        return btcAddress[ownerOf(_tokenId)];
    }

    function setPresalePhase(
        bool _state,
        TicketID ticket
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        presalePhase[ticket] = _state;
    }

    function setMaxSupply(
        uint256 _maxSupply
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxSupply = _maxSupply;
    }

    function setPresaleCost(
        uint256 _cost,
        TicketID ticket
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        presaleCost[ticket] = _cost;
    }

    function setPublicCost(
        uint256 _publicCost
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        publicCost = _publicCost;
    }

    function setPublicPhase(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
        publicSale = _state;
    }

    function setMintable(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
        mintable = _state;
    }

    function setBaseURI(
        string memory _newBaseURI
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseURL = _newBaseURI;
        emit BatchMetadataUpdate(_startTokenId(), totalSupply());
    }

    function withdraw() external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(_FUND_ADDRESS).transfer(address(this).balance);
    }

    function renounceOwnerMint() external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        renounceOwnerMintFlag = true;
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721A, IERC721A, AccessControl)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

    // ---------------------------------------------------------------
    // 既存関数のOverRide
    // ---------------------------------------------------------------

    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override(ERC721A, IERC721A) {
        require(
            _unlockedAddress[operator] == true,
            "Cannot approve, transferring not allowed"
        );
        super.setApprovalForAll(operator, approved);
    }

    // ---------------------------------------------------------------
    // 既存関数のOverRide
    // ---------------------------------------------------------------

    function approve(
        address operator,
        uint256 tokenId
    ) public payable virtual override(ERC721A, IERC721A) {
        require(
            _unlockedAddress[operator] == true,
            "Cannot approve, transferring not allowed"
        );
        super.approve(operator, tokenId);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override(ERC721A) {
        require(
            from == address(0) || _unlockedAddress[from] == true,
            "Send NFT not allowed"
        );
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }
}