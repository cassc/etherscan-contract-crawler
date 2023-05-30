// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";
import "base64-sol/base64.sol";

//                                                                          //
//                                                                      ///////***
//                                                                     //////******
//                                                                    /////********
//                                                                     ***********.
//                                 ((((((((((((////////        ///////    *****/
//                            #((((((((((((((//////////////////////*****
//                          ((((((((((((((///////////////////////*******
//                        (((((((((((((//////////////////////**********.
//                      (((((((((((((/////    /////////////**********
//                     ((((((((((((//                  //**********
//                    (((((((((////     ##(((((((((        *****
//                    (((((((/////    ((((((((((((((((((
//                    (((((///////    (((((((((((((((((((((
//                    (((/////////    (((((((((((((((((((((((
//                     ////////////      (((((((((((((((((((((
//                     ///////////////           (((((((((((((((
//                       //////////////*******      ((((((((((((
//                        ///////////************    ((((((((((((
//                          ///////**************    ((((((((((((
//                             /*****************    ((((((((((((
//                     (((((        /**********     (((((((((((((
//                  ((((((((((((                  ((((((((((((((
//                (((((((((((((((((((((((/  /((((((((((((((((((
//             ((((((((((((((((((((((((((((((((((((((((((((((
//             ((((((((((((((((((((((((((((((((((((((((((((
//             (((((((((((((((((((((((((((((((((((((((((/
//     (#((((    (((((((        ((((((((((((((((((((
//  ((((((((((((
//  ((((((((((((/
//  ((((((((((((
//   ((((((((((
contract ProbablySomethingGenesisPasses is Ownable, ERC721A, ReentrancyGuard {
    struct SaleConfig {
        uint256 mintPrice;
        bytes32 merkleRoot;
        uint256 maxPerWallet;
        uint16 maxSaleSupply;
    }

    struct TokenMetadata {
        string titleBase;
        string description;
        string website;
        string animationLocation;
        string imageLocation;
    }

    uint256 public constant MAX_SUPPLY = 555;
    bool public privateSaleOpen = false;

    SaleConfig saleData;
    TokenMetadata metadata;
    uint256 ownerSupply;
    uint16 privateSaleRound;
    mapping(uint16 => mapping(address => uint256)) allowListMinted;

    event Minted(address to, uint256 quantity);

    /**
     * @notice Initializes the contract with initial sale data.
     */
    constructor() ERC721A("Probably Something", "PSGENPASS") {
        metadata = TokenMetadata({
            titleBase: "Probably Something Genesis Pass",
            description: "A private community of 555 NFT collectors and creators. Each Genesis Pass grants total access to Probably Something - the products, the community, and partner projects - and a voice in what we create.",
            website: "https://probablysomething.io",
            animationLocation: "ipfs://bafybeifilun44e4leud5jqd7qld3nobfsiz5vjzart6wwcnzrgb4577boq",
            imageLocation: "ipfs://bafybeiesk4u6vttf2cbbkwlcou6k66nxbida73vdu74wvslzx6pikehsue"
        });
    }

    /**
     * @notice Starts a new sale phase for Genesis Passes.
     * @param price_ The price per token for the sale period.
     * @param merkleRoot_ the merkle root to use for allowlisting.
     * @param maxPerWallet_ the maximum that can be minted per wallet for the current sale period.
     * @param maxSaleSupply_ the total supply of public tokens available to be purchased by the end of the sale period.
     */
    function setNewSaleData(
        uint256 price_,
        bytes32 merkleRoot_,
        uint256 maxPerWallet_,
        uint16 maxSaleSupply_
    ) external onlyOwner {
        require(
            totalSupply() <= MAX_SUPPLY,
            "All passes have already been sold."
        );
        require(
            maxSaleSupply_ + ownerSupply <= MAX_SUPPLY,
            "Max supply for the sale with owner mints exceeds total token supply."
        );
        saleData = SaleConfig({
            merkleRoot: merkleRoot_,
            mintPrice: price_,
            maxPerWallet: maxPerWallet_,
            maxSaleSupply: maxSaleSupply_
        });
        privateSaleRound++;
    }

    /**
     * @notice Toggles sale status. Sale remains closed until @setUpNewSalePhase is called again.
     */
    function toggleSaleStatus(bool isOpen_) external onlyOwner {
        require(saleData.mintPrice != 0, "Sale data must be set first");
        _toggleSaleStatus(isOpen_);
    }

    /**
     * @notice Set the maximum number of mints per wallet.
     */
    function setMaxMint(uint256 max_) external onlyOwner {
        saleData.maxPerWallet = max_;
    }

    /**
     * @notice Set Merkle root for the sale.
     */
    function setMerkleRoot(bytes32 root_) external onlyOwner {
        saleData.merkleRoot = root_;
    }

    /**
     * @notice Sets the maximum sale supply.
     */
    function setMaxSaleSupply(uint16 max_) external onlyOwner {
        saleData.maxSaleSupply = max_;
    }

    /**
     * @notice Set the current sale price.
     */
    function setSalePrice(uint256 price_) external onlyOwner {
        saleData.mintPrice = price_;
    }

    /**
     * @notice Sets the base title on the token, which will be rendered with " #2" after.
     */
    function setTitleBase(string calldata titleBase_) external onlyOwner {
        metadata.titleBase = titleBase_;
    }

    /**
     * @notice Point to a new global animation location for the token.
     */
    function setAnimationLocation(string calldata loc_) external onlyOwner {
        metadata.animationLocation = loc_;
    }

    /**
     * @notice Point to a new global image location for the token.
     */
    function setImageLocation(string calldata loc_) external onlyOwner {
        metadata.imageLocation = loc_;
    }

    /**
     * @notice Set a new Description for the token.
     */
    function setDescription(string calldata desc_) external onlyOwner {
        metadata.description = desc_;
    }

    /**
     * @notice Point to a new website for the token.
     */
    function setWebsite(string calldata website_) external onlyOwner {
        metadata.website = website_;
    }

    /**
     * @notice Mint for owner. Can occur when sale is inactive
     */
    function ownerMint(uint256 quantity) external onlyOwner {
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "Reached max pass supply of genesis passes."
        );
        ownerSupply += quantity;
        _safeMint(msg.sender, quantity);
    }

    /**
     * @notice Mints genesis passes for allowlisted wallets subject to the current sale config.
     * @param quantity_ the quantity of passes to mint. Must match the amount of ETH sent.
     * @param merkleProof_ the merkle proof for the given msg.sender wallet
     */
    function allowlistMint(uint256 quantity_, bytes32[] calldata merkleProof_) external payable {
        require(privateSaleOpen, "Mint: sale is not open");
        require(
            totalSupply() - ownerSupply + quantity_ <= saleData.maxSaleSupply,
            "Mint: Cannot mint more than the max supply for the current sale period."
        );
        require(
            totalSupply() + quantity_ <= MAX_SUPPLY,
            "Mint: Reached max pass supply of genesis passes."
        );
        require(
            allowListMinted[privateSaleRound][msg.sender] + quantity_ <= saleData.maxPerWallet,
            "Mint: Amount exceeded."
        );
        require(
            msg.value == (saleData.mintPrice * quantity_),
            "Mint: Payment incorrect"
        );
        require(
            _isAllowlisted(msg.sender, merkleProof_),
            "Mint: User is not authorized to mint a genesis pass."
        );
        allowListMinted[privateSaleRound][msg.sender] =
            allowListMinted[privateSaleRound][msg.sender] +
            quantity_;
        _safeMint(msg.sender, quantity_);

        emit Minted(msg.sender, quantity_);
    }

    /**
     * @notice Withdraws ether from the contract.
     */
    function withdrawEther(address payable _to, uint256 _amount) external onlyOwner nonReentrant {
        _to.transfer(_amount);
    }

    /**
     * @notice Get the price of the current active sale.
     */
    function getSalePrice() public view returns (uint256) {
        require(privateSaleOpen, "Sale is not open.");
        return saleData.mintPrice;
    }

    /**
     * @notice Get the active merkle root for the sale.
     */
    function getActiveMerkleRoot() public view returns (bytes32) {
        require(privateSaleOpen, "Sale is not open.");
        return saleData.merkleRoot;
    }

    /**
     * @notice Returns the total number of tokens mintable for a given wallet.
     */
    function getMintableTokensForWallet(address account_, bytes32[] calldata merkleProof_) public view returns (uint32) {
        if (!_isAllowlisted(account_, merkleProof_)) {
            return 0;
        } else if (allowListMinted[privateSaleRound][account_] <= saleData.maxPerWallet) {
            return uint32(saleData.maxPerWallet - allowListMinted[privateSaleRound][account_]);
        } else { // unreachable code as long as sale data is valid
            return 0;
        }
    }

    /**
     * @notice Get current sale max supply.
     */
    function getCurrentMaxSaleSupply() public view returns (uint16) {
        require(privateSaleOpen, "Sale is not open.");
        return saleData.maxSaleSupply;
    }

    /**
     * @notice Override of the existing token URI for on-chain metadata.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        abi.encodePacked(
                            metadata.titleBase,
                            " #",
                            uint2str(tokenId)
                        ),
                        '","description":"',
                        metadata.description,
                        '","animation_url": "',
                        metadata.animationLocation,
                        '","image": "',
                        metadata.imageLocation,
                        '", "external_url": "',
                        metadata.website,
                        '", "attributes": [{"trait_type": "Generation","value": "0"},',
                        '{"trait_type": "Designer", "value": "Spongenuity"}',
                        "]}"
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    /**
     * @notice toggles sale status
     */
    function _toggleSaleStatus(bool isOpen_) internal {
        privateSaleOpen = isOpen_;
    }

    /**
     * @notice checks a leaf node of an address against the active merkle root.
     */ 
    function _isAllowlisted(address wallet_, bytes32[] calldata proof_) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(wallet_));
        return MerkleProof.verify(proof_, saleData.merkleRoot, leaf);
    }

    // ** - MISC - ** //
    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}