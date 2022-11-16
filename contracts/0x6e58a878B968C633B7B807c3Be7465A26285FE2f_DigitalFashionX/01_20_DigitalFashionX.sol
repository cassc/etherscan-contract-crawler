//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.13;

import "./interfaces/IPlanet.sol";

import "erc721a/contracts/extensions/ERC4907A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "operator-filter-registry/src/OperatorFilterer.sol";

/**
 * @title Digital Fashion-X
 * @author XiNG YUNJiA
 *
 * XTENDED iDENTiTY Projects - Digital Fashion-X
 */
contract DigitalFashionX is
    ERC2981,
    ERC4907A,
    Ownable,
    ReentrancyGuard,
    AccessControl,
    ERC721AQueryable,
    OperatorFilterer
{
    /* ============ Constant Variables ============ */
    bytes32 public constant RENT_ROLE = keccak256("RENT_ROLE");

    /* ============ State Variables ============ */
    // is mint paused
    bool public isPause = false;
    // Current number of series
    uint256 public seriesCounter;
    // metadata URI
    string private _baseTokenURI;
    // planet contract
    IPlanet public planet;
    // mint history
    mapping(uint256 => mapping(uint256 => bool)) public mintHistory;
    // series info
    mapping(uint256 => uint256) public seriesInfo;
    // filter marketplaces
    mapping(address => bool) public filteredAddress;

    /* ============ Event ============ */
    event Mint(
        address indexed owner,
        uint256 indexed planetId,
        uint256 indexed series,
        uint256 tokenId,
        uint256 index
    );

    /* ============ Modifiers ============ */

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "Only EOA address can mint");
        _;
    }

    /* ============ Constructor ============ */

    constructor()
        ERC721A("DigitalFashionX", "DFX")
        OperatorFilterer(
            address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6),
            true
        )
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /* ============ External Functions ============ */

    function mint(uint256 _tokenId, uint256 _series)
        external
        onlyEOA
        nonReentrant
    {
        require(isPause == false, "Mint is paused");
        require(
            planet.ownerOf(_tokenId) == msg.sender,
            "You are not the owner of this planet"
        );
        require(seriesCounter > 0 && _series > 0, "Series does not exist");
        require(_series <= seriesCounter, "Series does not exist");
        require(mintHistory[_series][_tokenId] == false, "You have minted");
        mintHistory[_series][_tokenId] = true;

        emit Mint(
            msg.sender,
            _tokenId,
            _series,
            _nextTokenId(),
            seriesInfo[_series]
        );

        _mint(msg.sender, 1);

        seriesInfo[_series] = seriesInfo[_series] + 1;
    }

    function setUser(
        uint256 _tokenId,
        address _user,
        uint64 _expires
    ) public override onlyRole(RENT_ROLE) {
        setUser(_tokenId, _user, _expires);
    }

    function setPause() external onlyOwner {
        isPause = !isPause;
    }

    function setSeriesNumber(uint256 _newSeries) external onlyOwner {
        seriesCounter = _newSeries;
    }

    function setPlanet(address _planet) external onlyOwner {
        planet = IPlanet(_planet);
    }

    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        _baseTokenURI = _baseURI;
    }

    function setFilteredAddress(address _address, bool _isFiltered)
        external
        onlyOwner
    {
        filteredAddress[_address] = _isFiltered;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function approve(address to, uint256 tokenId)
        public
        payable
        override(ERC721A, IERC721A)
    {
        require(!filteredAddress[to], "Not allowed to approve to this address");
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721A, IERC721A)
    {
        require(
            !filteredAddress[operator],
            "Not allowed to approval this address"
        );
        super.setApprovalForAll(operator, approved);
    }

    /* ============ External Getter Functions ============ */

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC721A, ERC4907A, ERC2981, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function getClaimStage(uint256 _tokenId)
        external
        view
        returns (bool[] memory, uint256)
    {
        bool[] memory _claimStages = new bool[](seriesCounter);

        for (uint256 i = 0; i < seriesCounter; i++) {
            _claimStages[i] = mintHistory[i + 1][_tokenId];
        }
        return (_claimStages, seriesCounter);
    }

    /* ============ Internal Functions ============ */

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
}