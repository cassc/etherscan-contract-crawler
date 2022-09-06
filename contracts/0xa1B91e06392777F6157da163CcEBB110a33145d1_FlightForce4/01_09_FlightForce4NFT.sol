/*

Flight Force 4

https://flightforce4.com/

https://twitter.com/flightforce4

*/

pragma solidity ^0.8.2;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract FlightForce4 is ERC721A, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;
    address public _signerAddress;
    address public _rankedSignerAddress;

    address _paySplitter;

    uint256 public SUPPLY = 11_111;

    uint256 public PUBLIC_PRICE = 0.075 ether;
    uint256 public WL_PRICE = 0.063 ether;
    uint256 public RANKED_PRICE = 0.05 ether;

    uint256 public WL_MAX_MINT = 3;
    uint256 public PUBLIC_TRANSACTION_MAX = 5;

    uint256 public MINT_STAGE = 0; //0 = No minting/Disabled, 1 = Whitelst, 2 = Public

    string public baseTokenURI;
    bool public baseTokenURILocked = false;
    bool public locked = false;

    mapping(address => uint256) public userNumMints;
    event BaseTokenURIChanged(string oldURI, string newURI);
    event PaymentsWithdrawn(address to, uint256 amount);

    constructor(address _signer, address _rankedSigner, string memory _baseTokenURI) ERC721A("FlightForce4", "FF4") {
        baseTokenURI = _baseTokenURI;
        _signerAddress = _signer;
        _rankedSignerAddress = _rankedSigner;
    }

    function setBaseMintPrice(uint256 _price) external onlyOwner{
        require(!locked, "Contract is locked");
        PUBLIC_PRICE = _price;
    }

    function setWLMintPrice(uint256 _price) external onlyOwner{
        require(!locked, "Contract is locked");
        WL_PRICE = _price;
    }

    function setRankedMintPrice(uint256 _price) external onlyOwner{
        require(!locked, "Contract is locked");
        RANKED_PRICE = _price;
    }

    function setSigner(address newSigner) external onlyOwner{
        _signerAddress = newSigner;
    }

    function setRankedSigner(address newSigner) external onlyOwner{
        _rankedSignerAddress = newSigner;
    }

    function setLocked() external onlyOwner{
        require(address(_paySplitter) != address(0), "Can't lock contract without payment splitter active.");
        locked = true;
    }

    function setPaymentAddress(address newPaysplitter) external onlyOwner{
        require(!locked, "Contract is locked");
        _paySplitter = newPaysplitter;
    }

    function setMintStage(uint256 stage) external onlyOwner {
        MINT_STAGE = stage;
    }

    function setMaxMintTransaction(uint256 maxMint) external onlyOwner {
        require(maxMint <= 50, "Max mint per transaction can't exceed 50.");
        PUBLIC_TRANSACTION_MAX = maxMint;
    }

    function signatureMatch(bytes calldata signature) public view returns (bool) {
        return _signerAddress == keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                bytes32(uint256(uint160(msg.sender)))
            )
        ).recover(signature);
    }

    function checkCanMint(uint256 numMint, uint256 mintPrice) internal view {
        uint256 mintedSupply = totalSupply();
        require(mintedSupply <= SUPPLY, "Sold Out!");
        require(mintedSupply + numMint <= SUPPLY, "Not enough supply to fulfill requested amount.");
        require(numMint <= getMaxMint(), "Too many mints in one transaction.");
        require(msg.value == (mintPrice * numMint), "Minting price does not match.");
    }

    function mint(uint256 numMint) external payable nonReentrant {
        require(MINT_STAGE == 2, "Public Minting is not yet enabled");
        checkCanMint(numMint, PUBLIC_PRICE);
        if (userNumMints[msg.sender] > 0){
            delete userNumMints[msg.sender];
        }
        _safeMint(msg.sender, numMint);
    }

    function signatureMint(uint256 numMint, uint256 mintStage, uint256 mintPrice, bytes calldata signature) internal {
        require(MINT_STAGE == mintStage, "Whitelist Minting not enabled");
        require(signatureMatch(signature), "Invalid signature. You are not on the list.");
        checkCanMint(numMint, mintPrice);
        require ((userNumMints[msg.sender] + numMint) <= WL_MAX_MINT, "Exceeded maximum whitelist mint.");
        userNumMints[msg.sender] += numMint;
        _safeMint(msg.sender, numMint);
    }

    function whitelistMint(uint256 numMint, bytes calldata signature) external payable nonReentrant{
        signatureMint(numMint, 1, WL_PRICE, signature);
    }

    function rankedMint(uint256 numMint, bytes calldata signature) external payable nonReentrant{
        signatureMint(numMint, 1, RANKED_PRICE, signature);
    }

    //Mint multiples, for reserving the initial team ones. 
    function mintFlightCrew(address recipient, uint256 num) public onlyOwner {
	    require(totalSupply() + num <= SUPPLY, "Not enough to mint");
        _safeMint(recipient, num);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        require(!baseTokenURILocked, "Base Token URI is locked from changing.");
        emit BaseTokenURIChanged(baseTokenURI, _baseTokenURI);
        baseTokenURI = _baseTokenURI;
    }

    function lockBaseTokenURI() external onlyOwner{
        baseTokenURILocked = true;
    }

    function dropSupply(uint newSupply) external onlyOwner{
        require(newSupply < SUPPLY, "New supply must be less than current supply.");
        require(newSupply > totalSupply(), "Can't set supply lower than current minted supply.");
        SUPPLY = newSupply;
    }

    function getMaxMint() public view returns (uint256) {
        if (MINT_STAGE == 0){
            return 0;
        }
        uint256 remainingSupply = getRemainingSupply();
        uint256 maxTransaction = PUBLIC_TRANSACTION_MAX;
        if (MINT_STAGE == 1){
            maxTransaction = WL_MAX_MINT;
            //Check against user mints
            uint256 userMints = userNumMints[msg.sender];
            if (userMints >= maxTransaction){
                return 0;
            }
            maxTransaction -= userMints;
        }

        if (remainingSupply < maxTransaction) {
            return remainingSupply;
        }
        return maxTransaction;
    }


    function getRemainingSupply() public view returns (uint256){
        return (SUPPLY - totalSupply());
    }

    function getMintedSupply() public view returns (uint256){
        return totalSupply();
    }


    function withdrawFunds(address to) public payable onlyOwner {
        require(!locked, "Contract is locked"); //Once contract is locked, no more direct withdrawals. Payment Splitter Withdrawals only
        uint balance = address(this).balance;
        (bool sent, ) = payable(to).call{value: address(this).balance}("");
        require(sent, "Error Withdrawing.");
        emit PaymentsWithdrawn(to, balance);
    }

    function withdrawFundsToSplitter() public payable {
        require(address(_paySplitter) != address(0), "Splitter not set.");
        uint balance = address(this).balance;
        (bool sent, ) = payable(_paySplitter).call{value: address(this).balance}("");
        require(sent, "Error Withdrawing.");
        emit PaymentsWithdrawn(_paySplitter, balance);
    }

    function withdrawERC(address _tokenContract) public payable onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        uint256 balance = tokenContract.balanceOf(address(this));
        require(balance > 0, "Nothing to withdraw.");
        tokenContract.transfer(msg.sender, balance);
    }
}