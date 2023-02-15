// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
// Uncomment this line to use console.log
import "hardhat/console.sol";

contract OmmuseNFT is ERC2981, ERC721URIStorage, Ownable, DefaultOperatorFilterer {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    //We want to maintain a default streaming royalty, and also allow
    //token specific royalty
    RoyaltyInfo private _defaultStreamingRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenStreamingRoyaltyInfo;

    struct Collaborator {
        address splitAddress;
        string accounts;
        string percentAllocations;
        uint96 distributorFee;
    }
    // Mapping from token ID to creator address. This could be a 0xSplitter contract too,
    // that may contain multiple creators.
    //mapping(uint256 => address) public tokenCollaborator;
    mapping(uint256 => Collaborator) public tokenCollaborator;

    //_contractUri - JSON containing details required by OpenSea
    //_royaltyInBips is in bips, means 1% = 100, 100%=10000, max value is 10000.
    //default royalty receiver is _contractOwner
    //We assume that _contractOwner( OmMuse) will be sale royalty and streaming royalty receiver
    //It is possible to have different royalty receiver and royalty per token too.

    constructor(
        string memory _name,
        string memory _symbol,
        address _contractOwner,
        address _saleRoyaltyReceiver,
        uint96 _saleRoyaltyInBips,
        address _streamingRoyaltyReceiver,
        uint96 _streamingRoyaltyInBips
    ) ERC721(_name, _symbol) {
        //console.log("************In constructor");
        //by default ownership goes to the account that deploys the contract,
        //but we want it to go to OmMuse address independent of deployer of the contract
        _transferOwnership(_contractOwner);

        //If no token specific royalty is defined while minting, then this sale royalty shall be used
        _setDefaultRoyalty(_saleRoyaltyReceiver, _saleRoyaltyInBips);

        //If no token specific streaming royalty is defined while minting, then this streaming royalty shall be used
        _setDefaultStreamingRoyalty(
            _streamingRoyaltyReceiver,
            _streamingRoyaltyInBips
        );
    }

    /***************************************
     *                                      *
     *           Functions related          *
     *           to Minting                 *
     *                                      *
     ***************************************/

    /// @notice Call this when wanting to mint a token having
    ///         * default sale royalty and receiver
    ///         * default streaming royalty and receiver
    /// @dev This function allows owner to mint an NFT with default values of sale and streaming royalties
    ///       that were set in the constructor during contract creation.
    /// @param
    /// @return tokenID of the freshly minted token

    function mintNFT(
        address _recipient,
        string memory _tokenURI,
        address _tokenCollaborator,
        string memory _accounts,
        string memory _percentAllocations,
        uint96 _distributorFee
    ) public onlyOwner returns (uint256) {
        _tokenIdCounter.increment(); //start from 1
        uint256 newItemId = _tokenIdCounter.current();
        _safeMint(_recipient, newItemId);
        _setTokenURI(newItemId, _tokenURI);
        tokenCollaborator[newItemId] = Collaborator(
            _tokenCollaborator,
            _accounts,
            _percentAllocations,
            _distributorFee
        );

        return newItemId;
    }

    /// @notice Call this when wanting to mint a token having
    ///         * sale royalty other than the default royalty and/or
    ///         * sale royalty receiver other than the default sale royalty receiver and/or
    ///         * streaming royalty other than the default royalty and/or
    ///         * streaming royalty receiver other than the default streaming royalty receiver
    /// @dev This function allows to override default sale and streaming royalty for this particular token
    ///      It calls mintNFT, and then sets the royalties additionally
    /// @param
    /// @return tokenID of the freshly minted token

    //
    //
    function mintNFTWithCustomRoyalty(
        address _recipient,
        string memory _tokenURI,
        address _tokenCollaborator,
        string memory _accounts,
        string memory _percentAllocations,
        uint96 _distributorFee,
        address _saleRoyaltyReceiver,
        uint96 _saleRoyaltyInBips,
        address _streamingRoyaltyReceiver,
        uint96 _streamingRoyaltyInBips
    ) external onlyOwner returns (uint256) {
        uint256 tokenId = mintNFT(
            _recipient,
            _tokenURI,
            _tokenCollaborator,
            _accounts,
            _percentAllocations,
            _distributorFee
        );
        _setTokenRoyalty(tokenId, _saleRoyaltyReceiver, _saleRoyaltyInBips);
        _setTokenStreamingRoyalty(
            tokenId,
            _streamingRoyaltyReceiver,
            _streamingRoyaltyInBips
        );

        return tokenId;
    }

    //Get token Count, we dont consdier burnt nfts as of now, as we are mainly using this to iterate over NFTs
    function tokenCount() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /***************************************
     *                                      *
     *           Functions related          *
     *           to Sale Royalty            *
     *                                      *
     ***************************************/
    /**

@dev Expose this inherited function, restricted to owner.
 */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @dev Expose this inherited function, restricted to owner.
     Removes default royalty information.
       deleting RoyaltyInfo, which is a struct means setting it to null
     */
    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    /**
     * @dev Expose this inherited function, restricted to owner.
     *      Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * @dev Expose this inherited function, restricted to owner.
     *      Resets royalty information for the token id back to the global default.
     */
    function resetTokenRoyalty(uint256 tokenId) external onlyOwner {
        _resetTokenRoyalty(tokenId);
    }

    /***************************************
     *                                      *
     *           Functions related          *
     *           to Streaming Royalty       *
     *                                      *
     ***************************************/
    /**
     * @dev Sets the streaming royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultStreamingRoyalty(address receiver, uint96 feeNumerator)
        internal
    {
        require(
            feeNumerator <= _feeDenominator(),
            "ERC2981: royalty fee will exceed salePrice"
        );
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultStreamingRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    function setDefaultStreamingRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultStreamingRoyalty(receiver, feeNumerator);
    }

    /**
     * @dev Sets the Streaming royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */

    function _setTokenStreamingRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal {
        require(
            feeNumerator <= _feeDenominator(),
            "ERC2981: royalty fee will exceed salePrice"
        );
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenStreamingRoyaltyInfo[tokenId] = RoyaltyInfo(
            receiver,
            feeNumerator
        );
    }

    function setTokenStreamingRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) public onlyOwner {
        _setTokenStreamingRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * @dev Resets Streaming royalty information for the token id back to the global default.
     */
    function resetTokenStreamingRoyalty(uint256 tokenId) external onlyOwner {
        delete _tokenStreamingRoyaltyInfo[tokenId];
    }

    /**
     * @dev Function that returns streaming royalty to be paid.
     */
    function streamingRoyaltyInfo(uint256 _tokenId, uint256 _salePrice)
        public
        view
        returns (address, uint256)
    {
        RoyaltyInfo memory royalty = _tokenStreamingRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultStreamingRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) /
            _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /***************************************
     *                                      *
     *           Functions related          *
     *           to revenue distribution    *
     *                                      *
     ***************************************/

    /**
     * @dev This function is called from offchain code
     * It is called when the NFT is sold for first time.
     * It is to be used when ETH is to be transferred to collaborators
     * It will send amount passed in msg.value to collaborators.
     * Note this amount may not be the actual sale amount paid by the buyer.
     * Buyer pays (SalePrice + gas)
     * OpenSea keeps 2.5% * SalePrice as its fees
     * OpenSea sends (SaleRoyalty%) * SalePrice to royalty receiver
     * OpenSea sends remaining amount to seller
     * We assume we are receving the "remaining amount" and hence send all of it to the collaborator.
     */
    function distributeInitialSaleRevenue(uint256 tokenId)
        external
        payable
        onlyOwner
    {
        require(ownerOf(tokenId) != address(0), "Token does not exist");
        address payable collaborator = payable(
            tokenCollaborator[tokenId].splitAddress
        );

        //Send amount that has come in msg.value to collaborator
        (bool sent, ) = collaborator.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }

    /**
    * @dev This function is called from offchain code
    * It is called when any streaming revenue is received for a token.  
    i.	If initial sale has not happened
    •	  It will send (amount-streamingRoyalty) to creators
    ii.	If initial sale has happened
    •	  It will send (amount-streamingRoyalty) to current owner
    •	  It will send streamingRoyalty*(1-streamingRoyalty) to creators

    */
    function distributeStreamingRevenue(uint256 tokenId, uint256 amount)
        external
        payable
        onlyOwner
    {}

    /***************************************
     *                                      *
     *            Misc Functions            *
     *                                      *
     ***************************************/

    /** @notice Hashes a split
     *  @param accounts Ordered, unique list of addresses with ownership in the split
     *  @param percentAllocations Percent allocations associated with each address
     *  @param distributorFee Keeper fee paid by split to cover gas costs of distribution
     *  @return computedHash Hash of the split.
     */
    function hashSplitGenerator(
        address[] memory accounts,
        uint32[] memory percentAllocations,
        uint96 distributorFee
    ) external pure returns (bytes32) {
        //console.log(abi.encodePacked(accounts, percentAllocations, distributorFee));
        return
            keccak256(
                abi.encodePacked(accounts, percentAllocations, distributorFee)
            );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
        delete tokenCollaborator[tokenId];
    }

    function burnNFT(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }

    //Overriding these methods to support Operator Filtering
    /* @notice This contract is configured to use the DefaultOperatorFilterer, which automatically registers the
     * token and subscribes it to OpenSea's curated filters.
     * Adding the onlyAllowedOperator modifier to the transferFrom and both safeTransferFrom methods ensures that
     * the msg.sender (operator) is allowed by the OperatorFilterRegistry. Adding the onlyAllowedOperatorApproval
     * modifier to the approval methods ensures that owners do not approve operators that are not allowed.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    //withdraw to owner wallet

    function withdraw() public onlyOwner {
        uint256 total = payable(address(this)).balance;
        (bool success, ) = payable(owner()).call{value: total}("");
        require(success, "eth withdraw failed");
    }

    //Withdraw any tokens sent to our contract
    function withdrawToken(address _tokenContract, uint256 _amount)
        external
        onlyOwner
    {
        ERC20 tokenContract = ERC20(_tokenContract);

        // transfer the token from address of this contract
        // to address of the owner()
        tokenContract.transfer(owner(), _amount);
    }

    //debug why unable to call tokenCollaborator from react.
    function collaboratorSplitAddress(uint256 tokenId)
        public
        view
        returns (address)
    {
        return tokenCollaborator[tokenId].splitAddress;
    }

    function collaboratorAccounts(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        return tokenCollaborator[tokenId].accounts;
    }

    function collaboratorShares(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        return tokenCollaborator[tokenId].percentAllocations;
    }

    function collaboratorDistributorFee(uint256 tokenId)
        public
        view
        returns (uint96)
    {
        return tokenCollaborator[tokenId].distributorFee;
    }
}