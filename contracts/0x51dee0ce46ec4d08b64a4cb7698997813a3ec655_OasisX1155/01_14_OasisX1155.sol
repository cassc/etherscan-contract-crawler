// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice tokens
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title OasisX 1155 contract
 * @author Cryptoware ME
 **/

contract OasisX1155 is ERC1155Supply, Pausable , ReentrancyGuard{
    /// @notice using Strings for uints conversion (tokenId)
    using Strings for uint256;

    /// @notice using Address for addresses extended functionality
    using Address for address;

    /// @notice using a counter to increment next Id to be minted
    using Counters for Counters.Counter;

    /// @notice Mapping minted tokens by address
    mapping(address => uint256) public minted;

    /// @notice tokenIds
    uint256 public tokenIds;

    /// @notice Price of token per ID
    mapping(uint256 => uint256) public mintPrice;

    /// @notice token id to be minted next
    Counters.Counter private _tokenIdTracker;

    /// @notice public metadata locked flag
    bool public locked = false;

    /// @notice address owner
    address public owner;

    /// @notice Token name
    string private _name;

    /// @notice Token symbol
    string private _symbol;

    /// @notice Address that will collect mint fees;
    address payable private _mintingBeneficiary;

    /// @notice Max token Id that can be minted;
    uint8 private maxId = 2;

    /// @notice factory address;
    address private factoryAddress;

    /// @notice Minting events definition
    event AdminMinted
    (
        address indexed to,
        uint256 indexed tokenId,
        uint256 quantity
    );

    event Minted
    (
        address indexed to,
        uint256 indexed tokenId,
        uint256 quantity
    );

    event MaxIdIncrementedwithPrice
    (
        uint256 indexed newId,
        uint256 indexed mintPrice
    );

    event MintCostChanged
    (
        uint256 indexed tokenId,
        uint256 indexed mintCost
    );

    event MintBeneficiaryChanged
    (
        address indexed beneficiary
    );

    event FactoryAddressChanged
    (
        address indexed FactoryAddress
    );

    event AvailableTokens
    (
        uint256[] indexed tokenIds,
        uint256[] indexed mintCosts
    );

    event OwnershipTransferred
    (
        address indexed oldOwner,
        address indexed newOwner
    );

    /// @notice metadata not locked modifier
    modifier notLocked() {
        require(!locked, "OasisX1155: Metadata URIs are locked");
        _;
    }

    /// @notice only owner modifier
    modifier onlyOwner() {
        require(msg.sender == owner, "OasisX1155: only owner");
        _;
    }

    /// @notice owner of factory modifier
    modifier ownerOrFactory(address account) {
        require(
            account == _msgSender() ||
                isApprovedForAll(account, _msgSender()) ||
                _msgSender() == factoryAddress,
            "OasisX1155: caller is not owner nor approved nor the factory"
        );
        _;
    }

    /**
     * @notice constructor
     * @param name_ the name of the Contract
     * @param symbol_ the token symbol
     * @param uri_ token metadata base uri
     **/
    constructor(
        string memory name_,
        string memory symbol_,
        string memory uri_,
        uint256[] memory tokenIds_,
        uint256[] memory mintCostPerTokenId_,
        address mbeneficiary_
    ) ERC1155(uri_) {
        require
        (
            mbeneficiary_ != address(0),
            "OasisX1155 : Address cannot be zero"
        );
        owner = msg.sender;
        _name = name_;
        _symbol = symbol_;
        _initialAddTokens(tokenIds_, mintCostPerTokenId_);
        _mintingBeneficiary = payable(mbeneficiary_);
    }

    ///@notice returns name of token
    function name() external view virtual returns (string memory) {
        return _name;
    }

    /// @notice returns symbol of token
    function symbol() external view virtual returns (string memory) {
        return _symbol;
    }

    /// @notice change max token Id
    function incrementMaxId(uint256 mintPrice_) external onlyOwner {
        maxId++;
        mintPrice[maxId] = mintPrice_;
        emit MaxIdIncrementedwithPrice(maxId, mintPrice_);
    }

    /// @notice returns max token Id
    function getMaxId() external view returns (uint8) {
        return maxId;
    }

    /**
     * @notice changes the minting cost
     * @param mintCost new minting cost
     **/
    function changeMintCost(uint256 mintCost, uint256 tokenId)
        external
        onlyOwner
    {
        require(
            mintCost != mintPrice[tokenId],
            "OasisX1155: mint Cost cannot be same as previous"
        );
        mintPrice[tokenId] = mintCost;
        emit MintCostChanged(tokenId, mintCost);
    }

    /**
     * @notice setting token URI
     * @param uri_ new URI
     */
    function setURI(string memory uri_) external onlyOwner {
        require(
            keccak256(abi.encodePacked(super.uri(0))) !=
                keccak256(abi.encodePacked(uri_)),
            "ERROR: URI same as previous"
        );
        _setURI(uri_);
    }

    /**
     * @notice return existing URI
     * @param id id of the token
     */
    function uri(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require
        (
            exists(id),
            "OasisX1155: Nonexistent token"
        );
        return string(abi.encodePacked(super.uri(0), id.toString(), ".json"));
    }

    /**
     * @notice nextId to mint
     **/
    function nextId() internal view returns (uint256) {
        return _tokenIdTracker.current();
    }

    /// @notice pausing the contract minting and token transfer
    function pause() external virtual onlyOwner {
        _pause();
    }

    /// @notice unpausing the contract minting and token transfer
    function unpause() external virtual onlyOwner {
        _unpause();
    }

    /**
     * @notice a function for admins to mint cost-free
     * @param to the address to send the minted token to
     * @param amount amount of tokens to mint
     **/
    function adminMint(
        address to,
        uint256 id,
        uint256 amount
    ) external whenNotPaused onlyOwner nonReentrant{
        require
        (
            to != address(0),
            "OasisX1155: Address cannot be 0"
        );

        require
        (
            id <= maxId,
            "OasisX1155: Token id mismatch"
        );

        minted[to] = amount;

        _mint(to, id, amount, "");

        emit AdminMinted(to, id, amount);
    }

    /**
     * @notice the public/presale minting function
     * @param to the address to send the minted token to
     * @param id id of the token to mint
     * @param amount quantity of tokens to mint
     **/
    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external payable nonReentrant{
        uint256 received = msg.value;

        require
        (
            to != address(0),
            "OasisX1155: Address cannot be 0"
        );
        require(
            received == mintPrice[id]*(amount),
            "OasisX1155: Ether sent mismatch with mint price"
        );
        require
        (
            id <= maxId,
            "OasisX1155: Token id mismatch"
        );

        minted[to] = amount;

        _mint(to, id, amount, "");

        emit Minted(to, id, amount);

        _forwardFunds(received);
    }

    /**
     * @notice changes the minting beneficiary
     * @param beneficiary new benefeciary address
     **/

    function changeMintBeneficiary(address beneficiary) external onlyOwner {
        require
        (
            beneficiary != address(0),
            "OasisX1155: Minting beneficiary cannot be address 0"
        );

        require
        (
            beneficiary != _mintingBeneficiary,
            "OasisX1155: beneficiary cannot be the same as previous"
        );
        _mintingBeneficiary = payable(beneficiary);
        emit MintBeneficiaryChanged(beneficiary);
    }

    /**
     * @notice transfer batch of tokens
     * @param from address to transfer from
     * @param to address to transfer to
     * @param ids ids of the token transfered
     * @param amounts amount of token to transfer
     * @param data data to pass while transfer
     */
    function batchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external {
        safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @notice transfer token
     * @param from address to transfer from
     * @param to address to transfer to
     * @param id id of the token transfered
     * @param amount amount of token to transfer
     * @param data data to pass while transfer
     */
    function transferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external {
        safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @notice burn function requires approval or factoryAddress
     * @param account address to transfer from
     * @param id address to transfer to
     * @param value id of the token transfered
     */
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external virtual ownerOrFactory(account) {
        _burn(account, id, value);
    }

    /**
     * @notice Change factory address
     * @param factoryAddress_ factory address which calls initialize proxy
     */
    function changeFactoryAddress(address factoryAddress_) external onlyOwner {
        require(
            factoryAddress != factoryAddress_,
            "OasisX1155: Address cannot be the same as previous"
        );
        factoryAddress = factoryAddress_;
        emit FactoryAddressChanged(factoryAddress_);
    }

    /**
     * @notice add initial token ids with their respective supplies
     * @param tokenIds_ list of token ids to be added
     * @param mintCostPerTokenId_ mint price per token Id
     **/
    function _initialAddTokens(
        uint256[] memory tokenIds_,
        uint256[] memory mintCostPerTokenId_
    ) private {
        require(
            tokenIds_.length == mintCostPerTokenId_.length,
            "OasisX1155: IDs/MintCost arity mismatch"
        );
        require(tokenIds_.length > 0, "OasisX1155: Please add tokens");
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            mintPrice[tokenIds_[i]] = mintCostPerTokenId_[i];
        }
        emit AvailableTokens(tokenIds_, mintCostPerTokenId_);
    }

    /**
     * @notice Determines how ETH is stored/forwarded on purchases.
     * @param received amount to forward
     */

    function _forwardFunds(uint256 received) internal {
        (bool success, ) = _mintingBeneficiary.call{value: received}("");
        require(success, "OasisX1155: Failed to forward funds");
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) external onlyOwner{
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @notice before token transfer hook override
     * @param operator address of the operator
     * @param from address to send tokens from
     * @param to address to send tokens to
     * @param ids ids of the tokens to send
     * @param amounts amount of each token
     * @param data data to pass while sending
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        require(!paused(), "OasisX1155: token transfer while paused");
    }
}