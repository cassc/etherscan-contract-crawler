// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "./ERC721APausable.sol";
import "./IBatchBurnable.sol";
import "erc721a/contracts/IERC721A.sol";
import {DefaultOperatorFilterer} from "../opensea/DefaultOperatorFilterer.sol";

contract MetaGoal is
    ERC721A,
    ERC721ABurnable,
    ERC721AQueryable,
    ERC721APausable,
    AccessControl,
    DefaultOperatorFilterer,
    Ownable
    {
    // Create a new role identifier for the minter role
    bytes32 public constant MINER_ROLE = keccak256("MINER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @dev Base token URI used as a prefix by tokenURI().
    string private baseTokenURI;
    string private collectionURI;
    mapping(address => bool) public disapprovedMarketplaces;
    constructor() ERC721A("METAGOAL", "MGOAL")
    {
        baseTokenURI = "https://cdn.metagoal.com/collection/metadata/";
        collectionURI = "https://cdn.metagoal.com/collection/contract.json";
        // Grant the contract deployer the default admin role: it will be able to grant and revoke any roles
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }
    function transferFrom(address from, address to, uint256 tokenId)
    public payable
    override(IERC721A,ERC721A)
    onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
    public payable
    override(IERC721A,ERC721A)
    onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    payable
    override(IERC721A,ERC721A)
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
    function mintTo(address to) public onlyRole(MINER_ROLE) {
        _safeMint(to, 1);
    }

    function mint(address to, uint256 quantity) public onlyRole(MINER_ROLE) {
        _safeMint(to, quantity);
    }

    function bulkBurn(uint256[] calldata tokenId) external{
        uint _len = tokenId.length;
        for(uint i=0;i<_len;i++){
            _burn(tokenId[i], true);
        }
    }

    function setDisapprovedMarketplace(address market, bool isDisapprove)
    external
    onlyRole(MINER_ROLE)
    {
        disapprovedMarketplaces[market] = isDisapprove;
    }

    function approve(address to, uint256 tokenId)
    public
    payable
    virtual
    override(IERC721A,ERC721A)
    onlyAllowedOperatorApproval(to)
    {
        require(!disapprovedMarketplaces[to], "The address is not approved");
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved)
    public
    virtual
    override(IERC721A,ERC721A)
    onlyAllowedOperatorApproval(operator)
    {
        require(
            !disapprovedMarketplaces[operator],
            "The address is not approved"
        );
        super.setApprovalForAll(operator, approved);
    }
    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "NFT: must have pauser role to pause"
        );
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "NFT: must have pauser role to unpause"
        );
        _unpause();
    }

    function current() public view returns (uint256) {
        return _totalMinted();
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function contractURI() public view returns (string memory) {
        return collectionURI;
    }

    function setContractURI(string memory _contractURI) public onlyRole(PAUSER_ROLE) {
        collectionURI = _contractURI;
    }

    /// @dev Returns an URI for a given token ID
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /// @dev Sets the base token URI prefix.
    function setBaseTokenURI(string memory _baseTokenURI) public onlyRole(PAUSER_ROLE) {
        baseTokenURI = _baseTokenURI;
    }

    function transferRoleAdmin(address newDefaultAdmin)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, newDefaultAdmin);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(IERC721A,ERC721A,AccessControl)
    returns (bool)
    {
        return
        super.supportsInterface(interfaceId) ||
        ERC721A.supportsInterface(interfaceId);
    }


    /**
    @dev tokenId to training start time (0 = not training).
     */
    mapping(uint256 => uint256) private trainingStarted;

    /**
    @dev Cumulative per-token training, excluding the current period.
     */
    mapping(uint256 => uint256) private trainingTotal;

    function trainingPeriod(uint256 tokenId)
    external
    view
    returns (
        bool training,
        uint256 currentT,
        uint256 total
    )
    {
        uint256 start = trainingStarted[tokenId];
        if (start != 0) {
            training = true;
            currentT = block.timestamp - start;
        }
        total = currentT + trainingTotal[tokenId];
    }

    /**
    @dev MUST only be modified by safeTransferWhiletraining(); if set to 2 then
    the _beforeTokenTransfer() block while training is disabled.
     */
    uint256 private trainingTransfer = 1;

    /**
    @notice Transfer a token between addresses while the MetaGoal is minting,
    thus not resetting the training period.
     */
    function safeTransferWhiletraining(
        address from,
        address to,
        uint256 tokenId
    ) external {
        require(ownerOf(tokenId) == _msgSender(), "MetaGoal: Only owner");
        trainingTransfer = 2;
        safeTransferFrom(from, to, tokenId);
        trainingTransfer = 1;
    }

    /**
    @dev Block transfers while training.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override (ERC721A, ERC721APausable){
        uint256 tokenId = startTokenId;
        for (uint256 end = tokenId + quantity; tokenId < end; ++tokenId) {
            require(
                trainingStarted[tokenId] == 0 || trainingTransfer == 2,
                "MetaGoals: training"
            );
        }
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    /**
    @dev Emitted when a MetaGoal begins training.
     */
    event Trained(uint256 indexed tokenId);

    /**
    @dev Emitted when a MetaGoal stops training; either through standard means or
    by expulsion.
     */
    event Untrained(uint256 indexed tokenId);

    /**
    @dev Emitted when a MetaGoal is expelled from the train.
     */
    event Expelled(uint256 indexed tokenId);

    /**
    @notice Whether training is currently allowed.
    @dev If false then training is blocked, but untraining is always allowed.
     */
    bool public trainingOpen = false;

    /**
    @notice Toggles the `trainingOpen` flag.
     */
    function setTrainingOpen(bool open) external onlyRole(PAUSER_ROLE)  {
        trainingOpen = open;
    }
    /**
    @notice Changes the MetaGoal's training status.
    */
    function toggleTraining(uint256 tokenId)
    internal
    {
        require(ownerOf(tokenId) == _msgSender(), "MetaGoal: Only owner");
        uint256 start = trainingStarted[tokenId];
        if (start == 0) {
            require(trainingOpen, "MetaGoals: training closed");
            trainingStarted[tokenId] = block.timestamp;
            emit Trained(tokenId);
        } else {
            trainingTotal[tokenId] += block.timestamp - start;
            trainingStarted[tokenId] = 0;
            emit Untrained(tokenId);
        }
    }

    /**
    @notice Changes the MetaGoals' training status
    @dev Changes the MetaGoals' training sheep (see @notice).
     */
    function toggleTraining(uint256[] calldata tokenIds) external {
        uint256 n = tokenIds.length;
        for (uint256 i = 0; i < n; ++i) {
            toggleTraining(tokenIds[i]);
        }
    }

    /**
    @notice Admin-only ability to expel a MetaGoal from the train.
     */
    function expelFromTrain(uint256 tokenId) external onlyRole(MINER_ROLE) {
        require(trainingStarted[tokenId] != 0, "MetaGoals: not trained");
        trainingTotal[tokenId] += block.timestamp - trainingStarted[tokenId];
        trainingStarted[tokenId] = 0;
        emit Untrained(tokenId);
        emit Expelled(tokenId);
    }


}