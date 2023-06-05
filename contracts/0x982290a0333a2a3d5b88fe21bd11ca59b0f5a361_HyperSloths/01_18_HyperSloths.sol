//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @author MSAPPS
/// @title HyperSloths.
contract HyperSloths is ERC721Enumerable, Ownable, PaymentSplitter, Pausable {
    /// @dev Variables

    bool public isWhiteListSaleOn = true; // False when whitelist sale is off.
    string private tokenBaseURI; // Metadata Prefix URI.
    bytes32 private whiteListMerkleRoot; // For Whitelist Validation.
    bytes32 private freeMintMerkleRoot; // For Freemint Validation.
    uint256 private publicMintLimit; // A number representing the maximum amount of mints for the public sale.
    mapping(address => uint256) private freeMintsAmount; // Counter for mint amount, Like balanceOf but doesn't change when transferring.
    mapping(address => uint256) private whiteListAmount; // Counter for mint amount, Like balanceOf but doesn't change when transferring.
    mapping(address => uint256) private publicAmount; // Counter for mint amount, Like balanceOf but doesn't change when transferring.

    /// @dev Contract Creation.

    constructor(
        address[] memory payees,
        uint256[] memory shares,
        bytes32 whitelistRoot,
        bytes32 freemintRoot,
        string memory base,
        uint256 maxMintAmount
    ) ERC721("HYPERSLOTHS", "HS") PaymentSplitter(payees, shares) {
        whiteListMerkleRoot = whitelistRoot;
        freeMintMerkleRoot = freemintRoot;
        tokenBaseURI = base;
        publicMintLimit = maxMintAmount;
        pause();
    }

    /// @dev Modifiers.

    /// @notice Access is allowed only to whitelisted users. this access limit is off if the whitelist sale is off.
    /// @param _address The address that called the function that activated this modifier.
    /// @param amount The amount this address is allowed to mint.
    /// @param proof Bytes array that is used for validation in the whitelist.
    modifier onlyWhiteListed(
        address _address,
        uint256 amount,
        bytes32[] memory proof
    ) {
        bool isWhiteListed = validateUser(
            proof,
            _leaf(_address, amount),
            whiteListMerkleRoot
        );
        require(
            (isWhiteListed) || (!isWhiteListSaleOn),
            "Mint: access is only for white listed or when whitelisted sale is off."
        );
        _;
    }

    /// @dev Functions.

    /// @notice Get the maximum amount of mints allowed for the public sale.
    /// @return uint256, A number representing the maximum amount of mints allowed.
    function getPublicMintLimit() public view returns (uint256) {
        return publicMintLimit;
    }

    /// @notice Change the maximum amount of mints allowed.
    /// @dev Only owner can activate this function.
    /// @param mintLimit The amount of mints allowed.
    function setPublicMintLimit(uint256 mintLimit) public onlyOwner {
        publicMintLimit = mintLimit;
    }

    /// @notice Reject every call to a function with the modifier 'whenNotPaused' until 'unpause' function is called.
    /// @dev Only owner can call this function.
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Accept every call to a function with the modifier 'whenNotPaused'.
    /// @dev Only owner can call this function.
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice Merkle Tree leaf function, this makes a hash that is used for validation in whitelist/freemint.
    /// @param _address The address that called the function that activated this hash function.
    /// @param amount If the user is in freemint than this is the amount of mints this address is supposed to get for free,
    /// If the user is in whitelist than this is the amount of mints this address is allowed to mint during whitelist sale.
    /// @return bytes32, The hash of the (address, amount) encodePacked together then hashed using keccak256.
    function _leaf(address _address, uint256 amount)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_address, amount));
    }

    /// @notice Changes the prefix url of the nft token, used for reveal.
    /// @dev Only owner can run this function.
    /// @param baseURI_ The CID of ipfs storage location.
    function setBaseURI(string memory baseURI_) public onlyOwner {
        tokenBaseURI = baseURI_;
    }

    /// @notice Returns the url prefix of the nft token.
    /// @return string, The url prefix of the nft token.
    function _baseURI() internal view override returns (string memory) {
        return tokenBaseURI;
    }

    /// @notice Returns the NFT metadata.
    /// @param tokenId The token id that we want to get its metadata.
    /// @return string, Concatenated baseURI, tokenName(Same as tokenId), json, Which results in url pointing to the token metadata.
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "HYPERSLOTHS: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        string memory tokenName = Strings.toString(tokenId);
        string memory json = ".json";
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenName, json))
                : "";
    }

    /// @notice Set a new whitelist merkle tree root.
    /// @dev When the whitelist has updated this function sets the root of the new tree.
    /// Only owner can run this function.
    function setWhiteListMerkleRoot(bytes32 root) public onlyOwner {
        whiteListMerkleRoot = root;
    }

    /// @notice Set a new freemint merkle tree root.
    /// @dev When the freemint has updated this function sets the root of the new tree.
    /// Only owner can run this function.
    function setFreeMintMerkleRoot(bytes32 root) public onlyOwner {
        freeMintMerkleRoot = root;
    }

    /// @notice Opening the mint for public.
    /// @dev Only owner can run this function.
    /// @return bool, Whitelist Status, True - Only whitelist can access, False - Everyone can access.
    function finishWhiteListSale() public onlyOwner returns (bool) {
        isWhiteListSaleOn = false;
        return isWhiteListSaleOn;
    }

    /// @notice Closing the mint for public, only whitelisted users are allowed to mint.
    /// @dev Only owner can run this function.
    /// @return bool, Whitelist Status, True - Only whitelist can access, False - Everyone can access.
    function reOpenWhiteListSale() public onlyOwner returns (bool) {
        isWhiteListSaleOn = true;
        return isWhiteListSaleOn;
    }

    /// @notice Mint An NFT.
    /// @dev Only whitelisted users can call this function, When whitelist sale is finished,
    /// everyone can call this function up to max 5 mints.
    /// @param _to The address that is getting the NFT.
    /// @param amount The amount the address is allowed to mint.
    /// @param proof A hash, proof that this user is verified in merkle tree.
    /// @return uint256, The newely minted NFT token id.
    function mintNFT(
        address _to,
        uint256 amount,
        bytes32[] memory proof
    )
        public
        payable
        onlyWhiteListed(_to, amount, proof)
        whenNotPaused
        returns (uint256)
    {
        // If the price paid for the nft is lower than this minimum then exit the function.
        require(msg.sender == tx.origin, "Bots are not allowed.");
        require(
            msg.value >= 0.25 ether,
            "Value sent is too low, send at least 0.25 ether."
        );
        require(
            amount == 0 || verifyAmountIntegrity(proof, _leaf(_to, amount)),
            "Amount cant be more than 0 if you are not in the whitelist or freemint."
        );
        /**
         *  First we check if the user is in the whitelist, then if he is in the whitelist
         *  We check if the whitelist sale is still going, if its still going we need to check if the amount
         *  of tokens the user own is less than his allowed amount,
         *  if the whitelist sale is off we get the amount of tokens the user own adding it the amount he
         *  is allowed to buy and we check if it exceeds the allowed amount.
         *  If the user in not in the whitelist we simply limit his address to 5 mints.
         **/
        require(
            isWhiteListSaleOn
                ? whiteListAmount[_to] < amount
                : balanceOfAddress(_to) < publicMintLimit + amount,
            "You have reached mint limit."
        );

        // If all the nfts are sold out exit the function.
        require(totalSupply() < 8000, "Out of nft tokens.");

        uint256 newItemId = totalSupply() + 1;
        _safeMint(_to, newItemId);
        // Incrementing the correct counter by 1 after each mint.
        isWhiteListSaleOn ? whiteListAmount[_to] += 1 : publicAmount[_to] += 1;

        return newItemId;
    }

    /// @notice Same as mint function but without validations.
    /// @dev Can be called only by the owner and can't mint more than 40 at a time.
    /// @param _to The address that is getting the NFT.
    /// @param amount The amount the address is allowed to mint.
    /// @param proof A hash, proof that this user is verified in merkle tree.
    function mintFreeNFT(
        address _to,
        uint256 amount,
        bytes32[] memory proof
    ) public onlyOwner {
        require(amount <= 40, "Cant Mint More Than 40 NFTs At A Time.");
        require(
            validateUser(proof, _leaf(_to, amount), freeMintMerkleRoot),
            "User Is Not In The Free Mint List."
        );
        for (uint256 i = 0; i < amount; i++) {
            uint256 newItemId = totalSupply() + 1;
            _safeMint(_to, newItemId);
        }
        // Incrementing the correct counter by the amount after each mint loop.
        freeMintsAmount[_to] += amount;
    }

    /// @notice Get The NFT Ids Owned By An Address.
    /// @param _address The owner of the nfts.
    /// @return uint256[], Array of token ids that the address owns.
    function getTokensByAddress(address _address)
        public
        view
        returns (uint256[] memory)
    {
        uint256 amount = balanceOf(_address);
        uint256[] memory tokens = new uint256[](amount);
        for (uint256 i = 0; i < amount; i++) {
            uint256 token = tokenOfOwnerByIndex(_address, i);
            tokens[i] = token;
        }
        return tokens;
    }

    /// @notice This function returns the balance that the contract holds.
    /// @dev Every transaction that is payable transfers the balance to the contract.
    /// @return uint256, The amount of wei in the contract.
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Check if the caller is in whitelist or freemint list.
    /// @param proof MerkleTree proof that the user is verified.
    /// @param leaf MerkleTree hash that is then verified by the root.
    /// @return bool, True - User is verified, False - User is not verified.
    function validateUser(
        bytes32[] memory proof,
        bytes32 leaf,
        bytes32 root
    ) public view returns (bool) {
        require(
            root == whiteListMerkleRoot || root == freeMintMerkleRoot,
            "root is not valid"
        );
        return MerkleProof.verify(proof, root, leaf);
    }

    /// @notice Check if the amount a user gave as parameter to the mint function is valid.
    /// @dev The amount is combined with the public key to create the leaf (parameter), that is why we are validating using merkle tree.
    /// If the amount is not valid the merkletree is not valid too.
    /// @param proof MerkleTree proof that the user is verified.
    /// @param leaf MerkleTree hash that is then verified by the root.
    /// @return bool, True - Amount is verified, False - Amount is not verified.
    function verifyAmountIntegrity(bytes32[] memory proof, bytes32 leaf)
        private
        view
        returns (bool)
    {
        bool whitelist = validateUser(proof, leaf, whiteListMerkleRoot);
        bool freelist = validateUser(proof, leaf, freeMintMerkleRoot);
        return whitelist || freelist;
    }

    /// @notice Get the amount of times a user minted nfts.
    /// @dev This is different from the balanceOf method because we don't check his amount of tokens, we check the amount of mints.
    /// @param _address The user we want to check how many times did mint.
    /// @return uint, The amount of times the user minted.
    function balanceOfAddress(address _address) public view returns (uint256) {
        uint256 balance = freeMintsAmount[_address] +
            whiteListAmount[_address] +
            publicAmount[_address];
        return balance;
    }

    event FallbackCalled(address sender, uint256 value, bytes data);

    /// @notice If no function is found this fallback function will trigger.
    /// @dev The emit event variables are to simply log the user
    fallback() external payable {
        emit FallbackCalled(msg.sender, msg.value, msg.data);
    }
}