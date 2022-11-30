// SPDX-License-Identifier: MIT
//                                                      *****+=:.  .=*****+-.      -#@@#-.   .+*****=:.     .****+:   :*****+=:.   -***:  -+**=   =***.
//                ...:=*#%%#*=:..       .+%@*.          @@@@%@@@@* .#@@@%%@@@*.  [email protected]@@@%@@@-  :%@@@%%@@@-    [email protected]@@@@#   [email protected]@@@%@@@@+  [email protected]@@-   #@@@:  %@@%
//             .:=%@@@@@@@@@@@@@@#-.  .#@@@@%:          @@@% .#@@%=.#@@*  [email protected]@@= -%@@#: #@@@: :%@@- [email protected]@@@   [email protected]@@#@@#   [email protected]@@* :%@@*: [email protected]@@-   [email protected]@@+ [email protected]@@.
//           .-%@@@@@@%%%%%%%%@@@@@@+=%@@@%*.           @@@%  :@@@*.#@@*  [email protected]@@= [email protected]@@-  *@@@- :%@@=..%@@@   [email protected]@%[email protected]@%:  [email protected]@@* [email protected]@#: [email protected]@@-    *@@@:%@@+
//          -%@@@@%##=.      :*##@@@@@@@%#.             @@@@:-*@@%=.#@@#::*@@%- [email protected]@@-  [email protected]@@= :%@@*+#@@@=   [email protected]@%[email protected]@@#  [email protected]@@#+#@@@=  [email protected]@@-    .#@@[email protected]@%
//        [email protected]@@@#*:              *@@@@@#-               @@@@@@@@#+ .#@@@@@@@@=  [email protected]@@-  [email protected]@@+.:%@@%##@@#:   @@@#.%@@#  [email protected]@@%#%@@#-. [email protected]@@-     [email protected]@@@@:
//       :*@@@@+.              .=%@@@#*.                @@@@***+.  .#@@%+*%@@#: [email protected]@@-  *@@@+ :%@@-  %@@@. [email protected]@@#=*@@%- [email protected]@@* :*@@@= [email protected]@@-      #@@@#
//      .#@@@%=              .-#@@@%#:    :             @@@%       .#@@*  [email protected]@@= [email protected]@@=  *@@@- :%@@-  [email protected]@@= [email protected]@@@@@@@@* [email protected]@@*  [email protected]@@= [email protected]@@-      *@@@:
//      [email protected]@@@=              :*@@@@#-.   .-%:            @@@%       .#@@*  [email protected]@@= -%@@*=-%@@#. :%@@*=-%@@@: @@@@++*@@@# [email protected]@@#--*@@%- [email protected]@@*----. *@@@:
//     [email protected]@@@+             :=#@@@#+:    [email protected]@*.           @@@%       .#@@*  [email protected]@@=  -#@@@@@@#:  :%@@@@@@@*+ [email protected]@@#  .*@@%[email protected]@@@@@@@#-  [email protected]@@@@@@@: *@@@:
//     [email protected]@@%            .-#@@@%*:      *@@@@.           +++=       .=++-  :+++:   :++++++.   .++++++++.  :+++:   :+++-.+++++++=:   -++++++++. -+++.
//     #@@@%           :*@@@@#-.       -%@@@.
//     %@@@%         :+#@@@#=:         :%@@@.                             .                                                        .
//     [email protected]@@%       .=#@@@@*:           [email protected]@@@.           ++++=  :++=   :++***++: .=+++++++++. =++=  .+++-  +++=  .+++=. :+++-   :++***++:
//     :@@@%-     :*@@@@#-.            *@@@%.           @@@@%  [email protected]@#  :#@@@#%@@#:-%@@@@@@@@@: %@@%. :@@@*  @@@%  :@@@@+ [email protected]@@+  :#@@%#@@@#:
//      @@@@#   .*#@@@#=:             =%@@@=            @@@@@= [email protected]@# [email protected]@@+:=%@@*:---#@@@+--. %@@%. :@@@*  @@@%  :@@@@#:[email protected]@@+ :%@@*::*@@@-
//      [email protected]@@@+ =#@@@@*:              -%@@@#.            @@@#@% [email protected]@# :%@@*. [email protected]@%-   *@@@-    %@@%. :@@@*  @@@%  :@@@@@[email protected]@@+ [email protected]@@=  :---.
//       [email protected]@@@#%@@@#-.              =%@@@@-             @@@[email protected]@*[email protected]@# [email protected]@@*   [email protected]@@=   *@@@-    %@@@#*#@@@*  @@@%  :@@%[email protected]%*@@@+ [email protected]@@= -****:
//        [email protected]@@@@@%=.              :*@@@@%-              @@@-%@%[email protected]@# [email protected]@@*   [email protected]@@=   *@@@-    %@@@@@@@@@*  @@@%  :@@#[email protected]@%@@@+ [email protected]@@= [email protected]@@@-
//        [email protected]@@@@*.              -#%@@@@+:               @@@=:@@%@@# [email protected]@@*   [email protected]@@=   *@@@-    %@@%-:[email protected]@@*  @@@%  :@@#[email protected]@@@@+ [email protected]@@= .*@@@-
//      .%@@@@%:.    :*+-:-=*#%%@@@@@%-                 @@@=.#@@@@# .*@@%- :#@@#:   *@@@-    %@@%. :@@@*  @@@%  :@@# [email protected]@@@@+ [email protected]@@=  [email protected]@@-
//     *%@@@@=.    :#%@@@%@@@@@@@@@*:.                  @@@= :@@@@#  [email protected]@@%+#@@@+    *@@@-    %@@%. :@@@*  @@@%  :@@#  [email protected]@@@+ .*@@@*+%@@@- -#%%:
//   :%@@@@#.     .#@@@@@@@@@@@@*:.                     @@@= .#@@@#   [email protected]@@@@@@+     *@@@-    %@@%. :@@@*  @@@%  :@@#  [email protected]@@@+  -%@@@@@@@@- :%@@:
//    .:-:.         ....:::.....                        ..     ...     ..:::..       ...      ..    ...   ...    ..    ....     .::.....    ..
//
/// @title Zero Genesis Pass
/// @author audie.eth
/// @notice This NFT gives you lifetime access to Product Ø

pragma solidity ^0.8.17;

import {ERC721} from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {ERC721Burnable} from '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import {ERC2981, IERC2981} from '@openzeppelin/contracts/token/common/ERC2981.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {MerkleProof} from '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import {DefaultOperatorFilterer} from 'operator-filter-registry/src/DefaultOperatorFilterer.sol';

contract ZeroGenesisPass is ERC721, ERC721Burnable, ERC2981, Ownable, DefaultOperatorFilterer {
    /**
     *  @notice Contructor for the NFT
     *  @param name The long name of the NFT collection
     *  @param symbol The short, all caps symbol for the collection
     */
    constructor(
        string memory name,
        string memory symbol,
        string memory openingContractURI,
        string memory openingTokenURI
    ) ERC721(name, symbol) ERC2981() Ownable() DefaultOperatorFilterer() {
        setDefaultRoyalty(royaltyAddr, royaltyPercent);
        contractURI = openingContractURI;
        _tokenURI = openingTokenURI;
    }

    ////////////////////////
    // Private Properties //
    ////////////////////////

    string private _tokenURI; // the tokenURI for all the NFTs
    uint256 private _mintedSupply; // the current minted supply (zero id is not used)
    mapping(address => bool) private _claims; // tracks allowListMints, each address only gets one

    ///////////////////////
    // Public Properties //
    ///////////////////////

    /**
     * @notice The URI of the contract's metadata json
     */
    string public contractURI;

    /**
     * @notice The maximum number of NFTs this contract will mint, ever.
     */
    uint256 public maxSupply = 500;

    /**
     * @notice The merkle root used to verify proofs for the allowListMint function
     * @dev Tree can be public since the message sender's address is used by contract to verify
     */
    bytes32 public merkleRoot;

    /**
     * @notice The current price for minting an NFT using the allowListMint function
     */
    uint256 public allowListMintPrice = 0.5 ether;

    /**
     * @notice The current price for minting an NFT using the mint function
     */
    uint256 public mintPrice = 1 ether;

    /**
     * @notice Boolean indicating if Minting is currently available
     */
    bool public mintOpen = true;

    /**
     * @notice Boolean indicating if Allow List Minting is currently available
     */
    bool public allowListMintOpen = true;

    ////////////////////////
    // EIP2981 Properties //
    ////////////////////////

    /**
     * @notice This is the address to receive any creator royalties, per ERC2981
     */
    address public royaltyAddr = 0x11d18ea67e081aa239430093808b2721b87ca733;

    /**
     * @notice The percentage of purchase price for creator fees, royaltyPercent
     */
    uint96 public royaltyPercent = 690; // denominator is 10000, so this is 6.9%

    ////////////
    // Events //
    ////////////

    event DefaultRoyaltyChanged(address receiver, uint96 feeNumerator);
    event ContractURIChanged(string newContractURI, string oldContractURI);
    event BaseURIChanged(string newURI, string oldURI);
    event MerkleRootChanged(bytes32 newMerkleRoot);
    event MintOpenChanged(bool newMintOpen);
    event AllowListMintOpenChanged(bool newAllowListMintOpen);
    event MintPriceChanged(uint256 newMintPrice);
    event AllowListMintPriceChanged(uint256 newAllowListMintPrice);
    event MaxSupplyChanged(uint256 newMaxSupply, uint256 oldMaxSupply);

    ////////////
    // Errors //
    ////////////

    error MintNotOpen();
    error AllowListMintNotOpen();
    error InsufficientEther(uint256 sent, uint256 required);
    error ClaimedAlready();
    error InvalidProof(address account, bytes32[] proof, bytes32 merkleRoot);
    error TokenDoesNotExist(uint256 tokenId);
    error CannotMintPastSupply(uint256 mintAttemptTokenId, uint256 maxSupply);
    error BadMaxSupplyValue(uint256 newMaxSupplyTry, uint256 totalSupply, uint256 maxSupplyBeforeTry);

    //////////////////////
    // External Methods //
    //////////////////////

    /**
     *  @notice Public mint function. Just checks mint is available and sender sent enough ETH
     */
    function mint() external payable {
        if (mintOpen == false) {
            revert MintNotOpen();
        }
        if (msg.value < mintPrice) {
            revert InsufficientEther({sent: msg.value, required: mintPrice});
        }
        address account = _msgSender();
        _mintOne(account);
    }

    /**
     *  @notice Given a caller whose address is in the given proof, mints the next NFT
     *  @param proof A merkle proof that uses the calling address as the data to verify
     *  @dev The merkle tree is publicly available, and this function uses the caller's address as data
     */
    function allowListMint(bytes32[] calldata proof) external payable {
        if (allowListMintOpen == false) {
            revert AllowListMintNotOpen();
        }
        if (msg.value < allowListMintPrice) {
            revert InsufficientEther({sent: msg.value, required: mintPrice});
        }
        // only the address on the merkle tree can mint, no others - means tree can be public
        address account = _msgSender();
        if (_claims[account] == true) {
            revert ClaimedAlready();
        }
        if (!_verify(proof, _leaf(account))) {
            revert InvalidProof({account: account, proof: proof, merkleRoot: merkleRoot});
        }
        _claims[account] = true;
        _mintOne(account);
    }

    /**
     *  @notice Owner only mint function to mint reserves or giveaways
     *  @param account The address to receive all the minted NFTs
     *  @param numberToMint The number of NFTs to mint
     */
    function ownerMint(address account, uint256 numberToMint) external onlyOwner {
        uint256 i;
        do {
            if (_mintedSupply + 1 <= maxSupply) {
                _mintOne(account);
            }

            ++i;
        } while (i < numberToMint);
    }

    ////////////////////
    // Public Methods //
    ////////////////////

    /**
     *  @notice Sets the max supply of tokens
     *  @param newSupply The new max supply of NFTs
     *  @dev This can only be set to a number between current maXSupply and the totalSupply (inclusive)
     */
    function setMaxSupply(uint256 newSupply) public onlyOwner {
        uint256 oldMaxSupply = maxSupply;
        if (newSupply > maxSupply || newSupply < _mintedSupply){
            revert BadMaxSupplyValue({newMaxSupplyTry: newSupply, totalSupply: _mintedSupply, maxSupplyBeforeTry: maxSupply});
        }
        maxSupply = newSupply;
        emit MaxSupplyChanged(newSupply, oldMaxSupply);
    }
    /**
     *  @notice Sets the ERC2981 default royalty info
     *  @param receiver The address to receive default royalty payouts
     *  @param feeNumerator The royalty fee in basis points, set over a denominator of 10000
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        super._setDefaultRoyalty(receiver, feeNumerator);
        emit DefaultRoyaltyChanged(receiver, feeNumerator);
    }

    /**
     *   @notice Sets the collection metadata URI
     *   @param newContractUri The URI for the collection metadata
     */
    function setContractURI(string memory newContractUri) public onlyOwner {
        string memory oldURI = contractURI;
        contractURI = newContractUri;
        emit ContractURIChanged(newContractUri, oldURI);
    }

    /**
     *   @notice Sets the token metadata base URI
     *   @param uri The baseURI for the token metadata json file
     *   @dev For this contract, this is every token's URI
     */
    function setBaseURI(string memory uri) public onlyOwner {
        string memory old = _tokenURI;
        _tokenURI = uri;
        emit BaseURIChanged(uri, old);
    }

    /**
     *  @notice Allows the owner to set a new merkle root for the allow list mint
     *  @param newMerkleRoot A merkle root created from a list of allow list minters
     */
    function setMerkleRoot(bytes32 newMerkleRoot) public onlyOwner {
        merkleRoot = newMerkleRoot;
        emit MerkleRootChanged(newMerkleRoot);
    }

    /**
     *  @notice Allows the owner to set the mint open or closed using a boolean
     *  @param newMintOpen The new boolean value to determine whether the mint is open
     */
    function setMintOpen(bool newMintOpen) public onlyOwner {
        mintOpen = newMintOpen;
        emit MintOpenChanged(mintOpen);
    }

    /**
     *  @notice Allows the owner to set the allowListMint open or closed using a boolean
     *  @param newAllowListMintOpen The new boolean value to determine whether the allowListMint is open
     */
    function setAllowListMintOpen(bool newAllowListMintOpen) public onlyOwner {
        allowListMintOpen = newAllowListMintOpen;
        emit AllowListMintOpenChanged(allowListMintOpen);
    }

    /**
     *  @notice Allows the owner to set the mint price
     *  @param newMintPrice The amount, in 18 digit ETH, to charge NFT minters
     */
    function setMintPrice(uint256 newMintPrice) public onlyOwner {
        mintPrice = newMintPrice;
        emit MintPriceChanged(mintPrice);
    }

    /**
     *  @notice Allows the owner to set the allowListMint price
     *  @param newAllowListMintPrice The amount, in 18 digit ETH, to charge allowList NFT minters
     */
    function setAllowListMintPrice(uint256 newAllowListMintPrice) public onlyOwner {
        allowListMintPrice = newAllowListMintPrice;
        emit AllowListMintPriceChanged(allowListMintPrice);
    }

    /**
     *  @notice Allows the owner to withdraw the Ether collected from minting, kinda important...
     */
    function withdrawEther() public onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }

    //////////////////
    // View Methods //
    //////////////////

    /**
     *   @notice Shows total existing supply, or minted supply
     *   @return mintedSupply Returns total minted supply
     */
    function totalSupply() public view returns (uint256) {
        // total supply is the total minted
        return _mintedSupply;
    }

    /**
     *  @notice Confirms an addressis on the allowList, and the proof is correct
     *  @param account The address to use in the merkle leaf
     *  @param proof The merkle proof on which you want to check validity against contract's merkle root
     *  @return canMint A boolean indicating whether the address given can mint with the given proof
     */
    function canAllowListMint(address account, bytes32[] calldata proof) public view returns (bool) {
        return _verify(proof, _leaf(account)) && _claims[account] != true;
    }

    ///////////////
    // Overrides //
    ///////////////

    /**
     *   @notice Overrides EIP721 and EIP2981 supportsInterface function
     *   @param interfaceId Supplied by caller this function, as defined in ERC 165
     *   @return supports A boolean saying whether this contract supports the interface or not
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return (interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId));
    }

    /**
     *  @notice Provides the URI for the specific token's metadata
     *  @param tokenId The token ID for which you want the metadata URL
     *  @return URI The URI of the JSON metadata for the NFT with tokenId
     *  @dev The URI is the same for every token in this contract
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) {
            revert TokenDoesNotExist({tokenId: tokenId});
        }
        return bytes(_tokenURI).length > 0 ? string(abi.encodePacked(_tokenURI)) : '';
    }

    /**
     *  @notice Transfers a token from one address to another, filtering out transfers from disallowed addresses
     *  @param from The address with the NFT to be tranferred
     *  @param to The address to receive the NFT
     *  @param tokenId The token ID of the NFT to transfer
     *  @dev This override is required by OpenSea to honor creator royalties
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     *  @notice Transfers a token from one address to another, filtering out transfers from disallowed addresses
     *  @param from The address with the NFT to be tranferred
     *  @param to The address to receive the NFT
     *  @param tokenId The token ID of the NFT to transfer
     *  @dev This will only transfer to an ERC721 receiver if the to address is a contract
     *  @dev This override is required by OpenSea to honor creator royalties
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     *  @notice Transfers a token from one address to another, filtering out transfers from disallowed addresses
     *  @param from The address with the NFT to be tranferred
     *  @param to The address to receive the NFT
     *  @param tokenId The token ID of the NFT to transfer
     *  @param data Optional data to send with the transfer, in this case unused.
     *  @dev This will only transfer to an ERC721 receiver if the to address is a contract
     *  @dev This override is required by OpenSea to honor creator royalties
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    ///////////////////////
    // Private Functions //
    ///////////////////////

    // The underlying mint function for all the mints above - checks not minting past supply
    function _mintOne(address account) internal {
        if (_mintedSupply >= maxSupply) {
            revert CannotMintPastSupply({mintAttemptTokenId: _mintedSupply, maxSupply: maxSupply});
        }
        _mintedSupply++;
        _safeMint(account, _mintedSupply);
    }

    // This creates the leaf for verification against the merkle root
    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    // Uses OpenZeppelin's merkle root tool to verify the given information
    function _verify(bytes32[] memory proof, bytes32 leaf) internal view returns (bool) {
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }
}