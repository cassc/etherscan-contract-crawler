// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract InhabitantsStories is ERC1155Burnable, AccessControl {
    using ECDSA for bytes32;

    string public name_;
    string public symbol_;
    address signer;
    uint256 public storyCounter; 

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    struct Story {
        uint128 windowOpens;
        uint128 windowCloses;
        string tokenUri;
        bool mintingFinalized;
        mapping(address => bool) hasMinted;
    }
    mapping(uint256 => Story) public stories;

    error windowClosed();
    error nonExistentToken();
    error signatureInvalid();
    error senderMintedBefore();

    event UriUpdated(uint256 indexed tokenId, string tokenUri);
    event StoryAdded(uint256 indexed tokenId, string tokenUri);

    modifier storyExists(uint256 _tokenId) {
        if (_tokenId >= storyCounter) revert nonExistentToken();
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _signer,
        address _adminWallet
    ) ERC1155("") {
        name_ = _name;
        symbol_ = _symbol;

        signer = _signer;

        _setupRole(DEFAULT_ADMIN_ROLE, _adminWallet);
        _setupRole(ADMIN_ROLE, _msgSender());         
    }

    /**
     * @notice Mints the given amount to receiver address
     *
     * @param _signature signature issued by PV
     * @param _tokenId token id wallet wants to mint
     * @param _amount amount to mint
     */
    function mint(
        bytes calldata _signature,        
        uint256 _tokenId,
        uint256 _amount
    ) external {
        Story storage story = stories[_tokenId];

        if (block.timestamp < story.windowOpens || block.timestamp > story.windowCloses || story.mintingFinalized) {
            revert windowClosed();
        }

        bytes32 hash = keccak256(
            abi.encodePacked(msg.sender, _tokenId, _amount)
        );
        if (hash.toEthSignedMessageHash().recover(_signature) != signer) {
            revert signatureInvalid();
        }

        if (story.hasMinted[msg.sender]) {
            revert senderMintedBefore();
        }
        story.hasMinted[msg.sender] = true;

        _mint(msg.sender, _tokenId, _amount, "");
    }  

    function addStory(
        uint128 _windowOpens,
        uint128 _windowCloses,
        string memory _tokenUri
    ) public onlyRole(ADMIN_ROLE) {
        require(_windowOpens < _windowCloses, "open window must be before close window");

        Story storage story = stories[storyCounter];
        story.windowOpens = _windowOpens;
        story.windowCloses = _windowCloses;
        story.tokenUri = _tokenUri;

        emit StoryAdded(storyCounter, _tokenUri);        

        storyCounter++;
    }

    function editURI(
        uint256 _tokenId,        
        string calldata _tokenUri
    ) external onlyRole(ADMIN_ROLE) storyExists(_tokenId) {
        stories[_tokenId].tokenUri = _tokenUri;

        emit UriUpdated(_tokenId, _tokenUri);        
    }    

    function editWindow(uint256 _tokenId, uint128 _windowOpens, uint128 _windowCloses) external onlyRole(ADMIN_ROLE) storyExists(_tokenId) {
        stories[_tokenId].windowOpens = _windowOpens;
        stories[_tokenId].windowCloses = _windowCloses;
    }

    function irrevocablyCloseMinting(uint256 _tokenId) external onlyRole(ADMIN_ROLE) storyExists(_tokenId) {
        stories[_tokenId].mintingFinalized = true;
    } 

    /**
     * @notice Mints the given amount to receiver address
     *
     * @param _receiver the receiving wallet
     * @param _tokenId the token id to mint
     * @param _amount the amount of tokens to mint
     */
    function ownerMint(
        address _receiver,
        uint256 _tokenId,
        uint256 _amount
    ) external onlyRole(ADMIN_ROLE) storyExists(_tokenId) {
        if (stories[_tokenId].mintingFinalized) {
            revert windowClosed();
        }

        _mint(_receiver, _tokenId, _amount, "");
    }

    /**
     * @notice Change the wallet address required to sign tickets
     *
     * @param _signer the new signing address
     *
     */
    function setSigner(
        address _signer
    ) external onlyRole(ADMIN_ROLE) {
        signer = _signer;
    }

    /**
     * @notice returns the metadata uri for a given id
     *
     * @param _id the id to return metadata for
     */
    function uri(
        uint256 _id
    ) public view override storyExists(_id) returns (string memory)  {
        return stories[_id].tokenUri;
    }

    function hasMinted(uint256 tokenId, address account) public view returns(bool) {
        return stories[tokenId].hasMinted[account];
    }  

    function name() public view returns (string memory) {
        return name_;
    }

    function symbol() public view returns (string memory) {
        return symbol_;
    }

    function supportsInterface(bytes4 interfaceId) public view override(AccessControl, ERC1155) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            interfaceId == type(IAccessControl).interfaceId || 
            interfaceId == type(IERC165).interfaceId ||         

            super.supportsInterface(interfaceId);
    }         
}