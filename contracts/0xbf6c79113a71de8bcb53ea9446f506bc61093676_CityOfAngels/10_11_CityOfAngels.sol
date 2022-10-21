// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

//   /$$$$$$  /$$   /$$                                /$$$$$$         /$$$$$$                                /$$
//  /$$__  $$|__/  | $$                               /$$__  $$       /$$__  $$                              | $$
// | $$  \__/ /$$ /$$$$$$   /$$   /$$        /$$$$$$ | $$  \__/      | $$  \ $$ /$$$$$$$   /$$$$$$   /$$$$$$ | $$  /$$$$$$$
// | $$      | $$|_  $$_/  | $$  | $$       /$$__  $$| $$$$          | $$$$$$$$| $$__  $$ /$$__  $$ /$$__  $$| $$ /$$_____/
// | $$      | $$  | $$    | $$  | $$      | $$  \ $$| $$_/          | $$__  $$| $$  \ $$| $$  \ $$| $$$$$$$$| $$|  $$$$$$
// | $$    $$| $$  | $$ /$$| $$  | $$      | $$  | $$| $$            | $$  | $$| $$  | $$| $$  | $$| $$_____/| $$ \____  $$
// |  $$$$$$/| $$  |  $$$$/|  $$$$$$$      |  $$$$$$/| $$            | $$  | $$| $$  | $$|  $$$$$$$|  $$$$$$$| $$ /$$$$$$$/
//  \______/ |__/   \___/   \____  $$       \______/ |__/            |__/  |__/|__/  |__/ \____  $$ \_______/|__/|_______/
//                          /$$  | $$                                                     /$$  \ $$
//                         |  $$$$$$/                                                    |  $$$$$$/
//                          \______/                                                      \______/

import {ERC721A} from "erc721a/ERC721A.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ICityOfAngels} from "./ICityOfAngels.sol";

/// @title City of Angels
/// @notice ERC721
contract CityOfAngels is ERC721A, ERC2981, Ownable, ICityOfAngels {
    /// @notice Contract Metadata
    /// @dev Used for OS https://docs.opensea.io/docs/contract-level-metadata
    string public contractURI = "https://cribbo.mypinata.cloud/ipfs/QmV2ZLBAaYc8Rx5msgiHSC9EcogtHcHcRwzVDz7cqkobAu";
    /// @notice BaseURI of Token Metadata
    string public baseURI = "https://cribbo.mypinata.cloud/ipfs/QmTrQyKwxc8y2eoLkNPdRFtx6GcME6bnLeQF7RajyPRwT3/";

    /// @notice Public sale price
    uint256 public publicPrice = 0.0357 ether;
    /// @notice Allowlist sale price
    uint256 public allowlistPrice = 0.0246 ether;
    /// @notice Maximum number of tokens
    uint256 public maxSupply = 2850;
    /// @notice Maximum mint quantity per transaction
    uint256 public mintAllowance = 5;
    /// @notice The merkle root for the allowlist
    bytes32 public allowlistMerkleRoot;
    /// @notice Public sale active or not
    bool public isPublicActive = false;
    /// @notice Allowlist sale active or not
    bool public isAllowlistActive = false;
    /// @notice Supply frozen or not
    /// @dev Once this is set to true, it cannot be undone
    bool public isSupplyFrozen = false;

    /// @notice Validating whether minting meets certain conditions
    modifier isMintable(uint256 _quantity) {
        if (_totalMinted() + _quantity > maxSupply) {
            revert MaxSupply();
        }
        if (_quantity > mintAllowance) {
            revert ExceedsMintAllowance();
        }
        if (tx.origin != msg.sender) { // solhint-disable-line avoid-tx-origin
            revert OnlyEoA();
        }
        _;
    }

    constructor(address owner_, address receiver_, uint256 initialMintQuantity_)
        Ownable()
        ERC721A("CityOfAngels", "COA")
    {
        require(owner_ != address(0) && receiver_ != address(0), "Invalid owner or receiver");
        _transferOwnership(owner_);
        _setDefaultRoyalty(receiver_, 500);
        if (initialMintQuantity_ > 0) {
            _mintERC2309(receiver_, initialMintQuantity_);
        }
    }

    /// @notice Allowlist Sale
    /// @param _merkleProof used to check whether an address is allowlisted
    /// @param _quantity the amount of tokens to mint
    function allowlistMint(bytes32[] calldata _merkleProof, uint256 _quantity)
        external
        payable
        isMintable(_quantity)
    {
        if (!isAllowlistActive) revert NotAllowlistPhase();
        if (allowlistPrice * _quantity != msg.value) {
            revert InvalidETHQuantity();
        }
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verify(_merkleProof, allowlistMerkleRoot, leaf)) {
            revert NotInAllowlist();
        }
        _safeMint(msg.sender, _quantity);
    }

    /// @notice Public Sale
    /// @param _quantity the amount of tokens to mint
    function mint(uint256 _quantity) external payable isMintable(_quantity) {
        if (!isPublicActive) revert NotPublicPhase();
        if (publicPrice * _quantity != msg.value) {
            revert InvalidETHQuantity();
        }
        _safeMint(msg.sender, _quantity);
    }

    /// @notice Team Mint
    /// @dev Only callable by contract owner
    /// @param _recipient the address that will receive the tokens
    /// @param _quantity the amount of tokens that will be minted
    function teamMint(address _recipient, uint256 _quantity)
        external
        onlyOwner
    {
        if (_totalMinted() + _quantity > maxSupply) revert MaxSupply();
        _safeMint(_recipient, _quantity);
    }

    /// @notice Airdrop
    /// @dev Only callable by contract owner
    /// @param _receivers the list of addresses that will receive tokens
    /// @param _quantities the list of token quantities for the receivers
    function airdrop(
        address[] calldata _receivers,
        uint256[] calldata _quantities
    ) external onlyOwner {
        if (_receivers.length != _quantities.length) revert LengthsMismatch();
        uint256 total;
        for (uint256 i = 0; i < _quantities.length; i++) {
            total += _quantities[i];
        }
        if (_totalMinted() + total > maxSupply) revert MaxSupply();
        for (uint256 i = 0; i < _receivers.length; i++) {
            _safeMint(_receivers[i], _quantities[i]);
        }
    }

    /// @notice Update the allowlist sale price
    /// @dev Only callable by contract owner
    /// @param _allowlistPrice the new price in wei
    function setAllowlistPrice(uint256 _allowlistPrice) external onlyOwner {
        allowlistPrice = _allowlistPrice;
    }

    /// @notice Update the public sale price
    /// @dev Only callable by contract owner
    /// @param _publicPrice the new price in wei
    function setPublicPrice(uint256 _publicPrice) external onlyOwner {
        publicPrice = _publicPrice;
    }

    /// @notice Update the contract metadata URI
    /// @dev Only callable by the contract owner
    /// @param _contractURI the new contract metadata URI
    function setContractURI(string calldata _contractURI) external onlyOwner {
        if (bytes(_contractURI).length == 0) {
            revert InvalidURI();
        }
        contractURI = _contractURI;
    }

    /// @notice Update the base URI for token metadata
    /// @dev Only callable by the contract owner
    /// @param _newBaseURI the new base URI for token metadata
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        if (bytes(_newBaseURI).length == 0) {
            revert InvalidURI();
        }
        baseURI = _newBaseURI;
    }

    /// @notice Open or close the public sale
    /// @dev Only callable by contract owner
    /// @param _active true for active, false for inactive
    function setIsPublicActive(bool _active) external onlyOwner {
        isPublicActive = _active;
    }

    /// @notice Open or close the allowlist sale
    /// @dev Only callable by contract owner
    /// @param _active true for active, false for inactive
    function setIsAllowlistActive(bool _active) external onlyOwner {
        isAllowlistActive = _active;
    }

    /// @notice Update the allowlist merkle root
    /// @dev Only callable by contract owner
    /// @param _merkleRoot the new merkle root
    function setAllowlistRoot(bytes32 _merkleRoot) external onlyOwner {
        allowlistMerkleRoot = _merkleRoot;
    }

    /// @notice Sets the royalty information that all ids in this contract will default to.
    /// @dev Only callable by contract owner
    /// @param _receiver cannot be the zero address.
    /// @param _feeNumerator cannot be greater than the fee denominator.
    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    // @notice Sets the royalty information that token ids.
    /// @dev to Resets royalty information set _feeNumerator to 0
    /// @param _tokenId the specific token id to Sets the royalty information for
    /// @param _receiver the address that will receive the royalty
    /// @param _feeNumerator cannot be greater than the fee denominator other case revert with InvalidFeeNumerator
    function setTokenRoyalty(
        uint256 _tokenId,
        address _receiver,
        uint96 _feeNumerator
    ) external onlyOwner {
        _setTokenRoyalty(_tokenId, _receiver, _feeNumerator);
    }

    /// @notice Freezing supply
    /// @dev This is not modifiable, once supply is frozen it cannot be changed
    ///      Only callable by contract owner
    function freezeSupply() external onlyOwner {
        isSupplyFrozen = true;
    }

    /// @notice Update maximum supply
    /// @dev Only callable by contract owner
    ///      Cannot be less than minted supply
    ///      Cannot be modified if supply has been frozen
    /// @param _supply the new supply amount
    function setMaxSupply(uint256 _supply) external onlyOwner {
        if (isSupplyFrozen) revert SupplyFrozen();
        if (_supply < _totalMinted()) revert SupplyLessThanMinted();
        maxSupply = _supply;
    }

    /// @notice Check whether an address is allowlisted
    /// @param _addr the address to check
    /// @param _merkleProof the proofs used to check
    /// @return Boolean, true = in allowlist
    function isAllowlisted(address _addr, bytes32[] calldata _merkleProof)
        external
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(_addr));
        return MerkleProof.verify(_merkleProof, allowlistMerkleRoot, leaf);
    }

    /// @notice Withdraw ETH from contract
    /// @dev Only callable by contract owner
    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{ // solhint-disable-line avoid-low-level-calls
            value: address(this).balance
        }("");
        if (!success) revert WithdrawTransfer();
    }

    /// @notice Token metadata URI
    /// @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
    /// @return the URI
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId)))
                : "";
    }

    /// @notice ERC165 interface support
    /// @param interfaceId the interface to check for
    /// @return Boolean
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return
            interfaceId == 0x2a55205a || // ERC165 Interface ID for ERC2981
            ERC721A.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}