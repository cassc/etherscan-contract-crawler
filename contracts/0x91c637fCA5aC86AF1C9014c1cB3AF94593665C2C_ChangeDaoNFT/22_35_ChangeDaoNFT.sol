// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import {DefaultOperatorFiltererUpgradeable} from "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import "../interfaces/IChangeDaoNFT.sol";

/**
 * @title ChangeDaoNFT
 * @author ChangeDao
 * @notice Implementation contract for clones created with ChangeDaoNFTFactory
 * @dev NOTE THE FOLLOWING USE OF THE OWNER PROPERTY:
 * @dev In the implementation contract, onlyOwner provides access control for the ChangeDao admin.
 * @dev In the clone contract, onlyOwner provides access control for the changeMaker.
 * @dev This change in onlyOwner allows for the clones to have an owner property that some market places use for authentication.
 */
contract ChangeDaoNFT is
    IChangeDaoNFT,
    ERC721Royalty,
    DefaultOperatorFiltererUpgradeable,
    Ownable
{
    /* ============== Libraries ============== */

    using Strings for uint256;

    /* ============== State Variables ============== */

    /// Implementation variables
    uint96 public override feeNumerator;
    IChangeDaoNFTFactory public override changeDaoNFTFactory;
    IController public override controller;
    /// Clone variables
    IChangeDaoNFT public override changeDaoNFTImplementation;
    address public override changeMaker;
    bool public override hasSetFundingClone;
    string public override baseURI;
    address public override fundingClone; // Needs to be address type!

    /* ============== Modifier ============== */

    /**
     * @dev onlyChangeMaker provides access control for the changeMaker in a clone.
     */
    modifier onlyChangeMaker() {
        require(_msgSender() == changeMaker, "NFT: ChangeMaker must be caller");
        _;
    }

    /* ============== Constructor ============== */

    /**
     * @notice Sets ERC721 name and symbol
     * @dev Prevents initialize() from being called on the implementation contract
     */
    constructor() ERC721("ChangeDAO.eth", "CHANGEDAO") initializer {}

    /* ============== Initialize ============== */

    /**
     * @notice Initializes the changeDaoNFTClone.
     * @dev _movementName, _projectName and _creators are all emitted and indexed offchain as project metadata.
     * @dev Only callable by ChangeDaoNFTFactory.
     * @param _changeMaker Address of the changeMaker that is making the project
     * @param _changeDaoNFTImplementation ChangeDaoNFTImplementation address
     * @param _movementName Movement with which the project is associated
     * @param _projectName Project name
     * @param _creators Array of addresses associated with the creation of the project
     * @param baseURI_ Base URI
     */
    function initialize(
        address _changeMaker,
        IChangeDaoNFT _changeDaoNFTImplementation,
        string calldata _movementName,
        string calldata _projectName,
        address[] calldata _creators,
        string memory baseURI_
    ) external override initializer {
        /** The clone calls its implementation contract to retrieve the address for the changeDaoNFTFactory. This needs to match the msgSender to prove that the call came from the factory. This prevents other factories from using ChangeDaoNFT.sol to create clones.*/
        require(
            _msgSender() ==
                address(_changeDaoNFTImplementation.changeDaoNFTFactory()),
            "NFT: Factory must be caller"
        );
        changeMaker = _changeMaker;
        baseURI = baseURI_;
        changeDaoNFTImplementation = _changeDaoNFTImplementation;
        _transferOwnership(_changeMaker);

        /**Subscribes to OpenSea's list of filtered operators and codehashes. The token contract owner may modify this list.  However, royalties on the OpenSea exchange will only be enforced if, at a minimum, the operators and codehashes in OpenSea's list are filtered.*/
        __DefaultOperatorFilterer_init();

        emit ChangeDaoNFTInitialized(
            _changeMaker,
            _changeDaoNFTImplementation,
            IChangeDaoNFT(this),
            _movementName,
            _projectName,
            baseURI_
        );

        for (uint256 i; i < _creators.length; i++) {
            emit CreatorRegistered(_creators[i]);
        }
    }

    /* ============== Mint Function ============== */

    /**
     * @dev This function can only be called by the funding clone associated with this changeDaoNFT clone. For the initial version of ChangeDao, all funding clones will be clones of SharedFunding.sol, but future versions will allow for other types of funding implementations.
     * @param _tokenId ERC721 token id
     * @param _owner Address that will be the token owner
     */
    function mint(uint256 _tokenId, address _owner) external override {
        require(
            _msgSender() == fundingClone,
            "NFT: Call is not from funding clone"
        );
        _safeMint(_owner, _tokenId);
    }

    /* ============== Getter Functions ============== */

    /**
     * @notice Returns URI for a specified token.  If the token id exists, returns the base URI appended with the token id.
     * @param _tokenId Token owner
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override(ERC721, IChangeDaoNFT)
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "NFT: ERC721Metadata: URI query for nonexistent token"
        );
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, _tokenId.toString()))
                : "";
    }

    /**
     * @notice Returns baseURI;
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /* ============== NFT Configuration Functions--Clone ============== */

    /**
     * @notice ChangeMaker sets base URI
     * @dev Any string over 32 bytes will be emitted as a hash of the string
     * @dev Only callable on clones, not the implementation contract
     * @param _newBaseURI New baseURI
     */
    function setBaseURI(string memory _newBaseURI)
        public
        override
        onlyChangeMaker
    {
        string memory _oldBaseURI = baseURI;
        baseURI = _newBaseURI;
        emit BaseURISet(_oldBaseURI, _newBaseURI);
    }

    /**
     * @notice The Controller contract sets the address of the funding clone that will call mint()
     * @dev The funding clone address can only be set once.
     * @param _fundingClone  fundingClone address
     * @param _changeDaoNFTClone changeDaoNFTClone address
     * @param _changeMaker Address of the changeMaker creating the fundingPSClone
     */
    function setFundingClone(
        address _fundingClone,
        IChangeDaoNFT _changeDaoNFTClone,
        address _changeMaker
    ) external override {
        require(
            _msgSender() == address(changeDaoNFTImplementation.controller()),
            "NFT: Controller must be caller"
        );
        require(
            _changeDaoNFTClone == IChangeDaoNFT(this),
            "NFT: Wrong changeDaoNFTClone"
        );
        require(_changeMaker == changeMaker, "NFT: Wrong changeMaker");
        require(
            _fundingClone != address(0x0),
            "NFT: Cannot set to zero address"
        );
        require(!hasSetFundingClone, "NFT: Funding clone already set");
        hasSetFundingClone = true;
        fundingClone = _fundingClone;
        emit FundingCloneSet(_fundingClone);
    }

    /**
     * @dev This function is called by the controller when a changeMaker creates a new royaltiesPSClone.
     * @param _receiver Address that receives royalties
     * @param _changeDaoNFTClone changeDaoNFTClone address
     * @param _changeMaker Address of the changeMaker
     */
    function setDefaultRoyalty(
        IPaymentSplitter _receiver,
        IChangeDaoNFT _changeDaoNFTClone,
        address _changeMaker
    ) external override {
        require(
            _msgSender() == address(changeDaoNFTImplementation.controller()),
            "NFT: Caller is not controller"
        );
        require(
            _changeDaoNFTClone == IChangeDaoNFT(this),
            "NFT: Wrong changeDaoNFTClone"
        );
        require(_changeMaker == changeMaker, "NFT: Wrong changeMaker");

        uint96 _feeNumerator = changeDaoNFTImplementation.feeNumerator();
        _setDefaultRoyalty(address(_receiver), _feeNumerator);
        emit DefaultRoyaltySet(_receiver, _feeNumerator);
    }

    /* ============== NFT Configuration Functions--Implementation ============== */

    /**
     * @dev ChangeDao admin sets the feeNumerator for royalty amount per sale.  feeNumerator is in basis points: 1000 = 10%.
     * @dev The function can only be called on the implementation contract.
     * @param _feeNumerator Royalty amount per sale
     */
    function setFeeNumerator(uint96 _feeNumerator) external override onlyOwner {
        require(
            changeMaker == address(0x0),
            "NFT: changeMaker not zero address"
        );
        feeNumerator = _feeNumerator;
    }

    /* ============ ERC721 Modifications for OpenSea Royalties Compliance ============= */

    function setApprovalForAll(address _operator, bool _approved)
        public
        override
        onlyAllowedOperatorApproval(_operator)
    {
        super.setApprovalForAll(_operator, _approved);
    }

    function approve(address _operator, uint256 _tokenId)
        public
        override
        onlyAllowedOperatorApproval(_operator)
    {
        super.approve(_operator, _tokenId);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override onlyAllowedOperator(_from) {
        super.transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override onlyAllowedOperator(_from) {
        super.safeTransferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) public override onlyAllowedOperator(_from) {
        super.safeTransferFrom(_from, _to, _tokenId, _data);
    }

    /* ============== Contract Address Setter Functions ============== */

    /**
     * @notice Sets address for the ChangeDaoNFTFactory contract
     * @dev ChangeDao admin sets the ChangeDaoNFTFactory address before ChangeDaoNFT is used as the implementation contract for clones.  The ChangeDaoNFTFactory address is used for a security check so that only the ChangeDaoNFTFactory can make use of the ChangeDaoNFT contract as an implementation contract.
     * @dev The function can only be called on the implementation contract.

     * @param _changeDaoNFTFactory ChangeDaoNFTFactory address
     */
    function setChangeDaoNFTFactory(IChangeDaoNFTFactory _changeDaoNFTFactory)
        external
        override
        onlyOwner
    {
        require(
            changeMaker == address(0x0),
            "NFT: changeMaker not zero address"
        );
        changeDaoNFTFactory = _changeDaoNFTFactory;
    }

    /**
     * @notice Sets address for the Controller contract
     * @dev The function can only be called on the implementation contract.
     * @param _controller Controller address
     */
    /**@notice Sets address for the Controller contract*/
    function setController(IController _controller)
        external
        override
        onlyOwner
    {
        require(
            changeMaker == address(0x0),
            "NFT: changeMaker not zero address"
        );
        controller = _controller;
    }
}