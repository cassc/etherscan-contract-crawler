pragma solidity ^0.8.4;

import 'erc721a-upgradeable/contracts/ERC721AUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "./Base64.sol";
import "./IERC2981Upgradable.sol";


/**
* @title ERC721A Minting Contract
* @author Osaka Toni Thomas - Autominter
*/
contract AutoMinterERC721A is Initializable, ERC721AUpgradeable, OwnableUpgradeable, IERC2981Upgradeable
{
    string private baseURI;
    address constant private shareAddress = 0xE28564784a0f57554D8beEc807E8609b40A97241;
    uint256 public MINT_FEE;
    bool private publicMintEnabled;
    
    uint256 public remaining;
    mapping(address => uint256) public accountMintCount;

    address private whiteListSignerAddress;
    uint256 public MAX_MINTS_PER_WALLET;
    uint256 public royaltyBasis = 1000;
    uint256 public ammountWithdrawn = 0;
    string public placeholderImage;
    bool public lockBaseUri;
    uint256 public reserve;

    constructor(){}

    function initialize(string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address ownerAddress_,
        uint256 mintFee_,
        uint256 size_,
        address whiteListSignerAddress_,
        uint256 mintLimit_,
        uint256 royaltyBasis_,
        string memory placeholderImage_) public initializer  {

        __ERC721A_init(name_, symbol_);
        baseURI = baseURI_;
        MINT_FEE = mintFee_;
        publicMintEnabled = true;
        _transferOwnership(ownerAddress_);
        remaining = size_;
        whiteListSignerAddress = whiteListSignerAddress_;
        MAX_MINTS_PER_WALLET = mintLimit_;
        royaltyBasis = royaltyBasis_;
        placeholderImage = placeholderImage_;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    
    /**
     * @notice Mint a "quantity" of NFTs from the collection
     * @dev You can mint using this function only when public mint is enabled
     * @param quantity The quantity of tokens that you want to mint
     */
    function mint(uint256 quantity) payable public
    {
        require(quantity > 0, 'Quantity must be greater than zero');
        require(publicMintEnabled == true, 'Public minting is not enabled for this contract yet');
        require(msg.value == MINT_FEE * quantity, 'Eth sent does not match the mint fee');
        
        _updateUserMintCount(msg.sender, quantity, 0);

        _updateMintCount(quantity);
        _safeMint(msg.sender, quantity);
    }
    
    /**
     * @notice Mint tokens if you are on the access list. It is recommended to use the minting app for this
     * @dev Signature and parameters must be provided by the project creator
     */
    function mintWithSignature(bool isFree, address to, uint256 customFee, uint256 limit, uint256 quantity, bytes calldata signature) payable public
    {
        require(quantity > 0, 'Quantity must be greater than zero');
        require(quantity <= limit || limit == 0, 'You are not able to mint more than the allocated limit at once');

        _updateUserMintCount(to, quantity, limit);

        /* Hash the content (isFree, to, tokenID) and verify the signature from the owner address */
        address signer = ECDSA.recover(
                ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(isFree, to, uint256(0), true, limit, customFee))),
                signature);
            
        require(signer == owner() || signer == whiteListSignerAddress, "The signature provided does not match");
        
        /* If isFree then do not splitPayment, else splitPayment */
        if(!isFree){

            /* If custom fee is not provided use, mint fee */
            if(customFee == 0){
                require(msg.value == MINT_FEE * quantity, 'Eth sent does not match the mint fee');
            }
            /* If custom fee is provided use, the custom fee */
            else{
                require(msg.value == customFee * quantity, 'Eth sent does not match the mint fee');
            }

            // _splitPayment();
        }
        
        _updateMintCount(quantity);
        _safeMint(to, quantity);
    }
    
    /**
     * @notice Airdrop tokens  (ADMIN ONLY FUNCTION)
     * @dev Admins can mint tokens to specific wallets 
     * @param to Address to mint the token too
     * @param quantity The quantity of tokens that you want to airdrop
     */
    function airdrop(address to, uint256 quantity) onlyOwner() public
    {
        _updateMintCount(quantity);
        _safeMint(to, quantity);
    }
    
    /**
     * @notice Airdrop tokens to multipl wallets (ADMIN ONLY FUNCTION)
     * @dev Admins can mint tokens to specific wallets, use this to airdrop to multiple addresses 
     * @param to List of addresses to mint the token too
     */
    function airdrop(address[] calldata to) onlyOwner() public
    {
        for (uint i=0; i<to.length; i++) {
            _updateMintCount(1);
            _safeMint(to[i], 1);
        }
    }
    
    function _updateUserMintCount(address account, uint256 quantity, uint256 customLimit) internal {
        // increment a mapping for user on how many mints they have
        uint256 count = accountMintCount[account];

        if(customLimit == 0){
            require(count + quantity <= MAX_MINTS_PER_WALLET || MAX_MINTS_PER_WALLET == 0, "Mint limit for this account has been exceeded");
        }
        else{
            require(count + quantity <= customLimit, "Mint limit for this account has been exceeded");
        }

        accountMintCount[account] = count + quantity;
    }
    
    function _updateMintCount(uint256 quantity) internal {
        require(quantity <= remaining, "Not enough mints remaining");
        require(quantity <= remaining - reserve, "Not enough unreserved mints available");
        remaining -= quantity;
    }
    
    function isTokenAvailable(uint256 tokenID) external view returns (bool)
    {
        return !_exists(tokenID);
    }

    /**
     * @notice Turn on or off the ability for anyone to mint (ADMIN ONLY FUNCTION)
     * @dev Admins can mint tokens to specific wallets, use this to airdrop to multiple addresses 
     */
    function togglePublicMinting() onlyOwner() public
    {
        publicMintEnabled = !publicMintEnabled;
    }

    /**
     * @notice Change the default mint price (ADMIN ONLY FUNCTION)
     * @dev Admins can change the mint price for the initial minting of tokens
     * @param mintFee_ The price to set the mint too in WEI
     */
    function changeMintFee(uint256 mintFee_) onlyOwner() public
    {
        MINT_FEE = mintFee_;
    }

    /**
     * @notice Change the max mints per wallet (ADMIN ONLY FUNCTION)
     * @dev Admins can change the max number of mints per wallet (0 = unlimitted)
     * @param mintLimit_ The maximum number of mints per wallet
     */
    function changeMintLimit(uint256 mintLimit_) onlyOwner() public
    {
        MAX_MINTS_PER_WALLET = mintLimit_;
    }


    /**
     * @notice Change the number of reserved NFTs (ADMIN ONLY FUNCTION)
     * @dev Admins can change the number of NFTs which cannot be minted and will be reserved
     * @param ammount The number of tokens to reserve
     */
    function updateReserveAmmount(uint256 ammount) onlyOwner() public
    {
        require(ammount <= remaining, "Reserve ammount must be less than remaining quantity");
        reserve = ammount;
    }

    /**
     * @notice Change the image for delayed reveal (ADMIN ONLY FUNCTION)
     * @dev Admins can change the delayed reveal image, only if the artwork has not been revealed yet
     * @param placeholderImage_ the uri of the image to use
     */
    function changePlaceholderImage(string memory placeholderImage_) onlyOwner() public
    {
        require(bytes(placeholderImage).length != 0, "Metadata has already been revealed");
        require(bytes(placeholderImage_).length != 0, "Placeholder image cannot be empty");

        placeholderImage = placeholderImage_;
    }

    function royaltyInfo(uint _tokenId, uint _salePrice) external view returns (address receiver, uint royaltyAmount) {
        return (address(this), uint((_salePrice * royaltyBasis)/10000));
    }
    

    /**
     * @notice Transfer the balance of in contract (ADMIN ONLY FUNCTION)
     * @dev Admins can transfer the balance in the contract
     * @param to the address to send funds too
     * @param ammount the ammount to transfer in WEI ((Make equal to balance)
     */
    function transferBalance(address payable to, uint256 ammount) onlyOwner() public{
        
        if(address(this).balance != 0){
            require(address(this).balance <= ammount, "Not enought Balance to Transfer");

            uint256 splitValue = ammount / 10;
            uint256 remainingValue = ammount - splitValue;
            
            payable(shareAddress).transfer(splitValue);
            payable(to).transfer(remainingValue);
            ammountWithdrawn += ammount;
        }
    }
    
    /**
     * @notice Transfer ERC20  balance of in contract (ADMIN ONLY FUNCTION)
     * @dev Admins can transfer the balance in the contract
     * @param erc20ContractAddress the address of the ERC20 token which is held and should be transfered
     * @param to the address to send
     * @param ammount the ammount to transfer in the base unit of the ERC20 token
     */
    function transferERC20Balance(address erc20ContractAddress, address payable to, uint256 ammount) onlyOwner() public{
        uint256 splitValue = ammount / 10;
        uint256 remainingValue = ammount - splitValue;

        IERC20(erc20ContractAddress).transfer(shareAddress, splitValue);
        IERC20(erc20ContractAddress).transfer(to, remainingValue);
    }
    
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(
                bytes(
                    string(abi.encodePacked('{"name":"', name(), '","seller_fee_basis_points":', Strings.toString(royaltyBasis), ',"fee_recipient":"', "0x", toAsciiString(address(this)), '"}' ))
                )
            )
        ));
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721AUpgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721AUpgradeable).interfaceId ||
            // interfaceId == type(IERC721AMetadataUpgradeable).interfaceId ||
            interfaceId == type(IERC2981Upgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function IS_PUBLIC_MINTING_OPEN() external view returns (bool){
        return publicMintEnabled;
    }
    
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();

        if(bytes(placeholderImage).length > 0){
            return placeholderImage;
        }
        else{
            return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId))) : "";
        }

    }

    /**
     * @notice Reveal the artwork (ADMIN ONLY FUNCTION)
     * @dev Reveal the artwork if you have delayed reveal on
     */
    function reveal() onlyOwner() public {
        placeholderImage = "";
    }

    /**
     * @notice Change the base URI for the artwork and metadata (ADMIN ONLY FUNCTION)
     * @dev You can change the base tokenURI if you have not locked the base uri from being updated
     * @param baseURI_ URI of the collection
     */
    function changeBaseUri(string memory baseURI_) onlyOwner() public {
        require(!lockBaseUri, "Base URI is locked, it cannot be edited");

        baseURI = baseURI_;
    }

    /**
     * @notice Permenantly lock the base URI so the artwork can never be changed (ADMIN ONLY FUNCTION)
     * @dev Lock the base uri so that it is permenant and cannot be changed in the future ever
     */
    function permanentlyLockBaseUri() onlyOwner() public {
        lockBaseUri = true;
    }

    function getMintsUsed(address account) external view returns (uint256) {
        return accountMintCount[account];
    }
    
    function version() external pure returns (string memory)
    {
        return "2.0.0";
    }

    receive() external payable {}
}