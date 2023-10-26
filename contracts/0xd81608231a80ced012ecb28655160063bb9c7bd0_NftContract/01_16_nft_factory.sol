// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20 {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

error NoFundsAvailableForWithdraws();
error ReferralFeeDisabled();
error paymentFailed();
error NftSaleAlreadyStarted();
error InsufficientFunds();

contract NftContract is Ownable, ERC721Enumerable, IERC2981 {

    using Strings for uint256;

    struct Settings {
        uint totalSupply;
        uint mintFee;
        uint startTime;
        uint EndTime;
        uint RefFee;
    }

    uint private constant platformCommission = 3;
    address public  platformVault;   // put the platform fee wallet here

    uint public adminWithdraw;

    address private royaltyReceiver;
    uint256 private royaltyPercentage;

    Settings public saleSetting;
    address public adminfeeWallet;

    string public ipfsuri;

    mapping (address => uint) public refferalFee;
    mapping (address => uint) public refWithdraws;

    mapping (address => mapping(address => bool)) internal refferedAddress;
    mapping (address => uint) public refferalCount;

    uint public fundsraised;

    event nftPurchase(address indexed _buyer,uint indexed _token);
    event fundsWithdraw(address indexed from,address indexed to,uint _value);
    event referralFundsWithdraw(address indexed from, address indexed recieverWallet, uint _value);

    modifier isLive() {
        require(saleSetting.startTime != 0 && saleSetting.EndTime != 0,"Sale: Invalid Timer!");
        require(block.timestamp >= saleSetting.startTime && block.timestamp <= saleSetting.EndTime,"Sale: Time error!");
        _;
    }

    modifier mintCompliance(uint _amount) {
        require(totalSupply() + _amount <= saleSetting.totalSupply,"Sale: All Sold Out");
        _;
    }

    constructor(
        string memory name, 
        string memory symbol,
        uint[6] memory setter,
        address royalityReciever,
        string memory _baseuri,
        address feeWallet,
        address initializer,
        address platformAddr
        ) ERC721(name, symbol) {

            adminfeeWallet = feeWallet;

            saleSetting.totalSupply = setter[0];
            saleSetting.startTime = setter[1];
            saleSetting.EndTime = setter[2];
            saleSetting.RefFee = setter[3];
            saleSetting.mintFee = setter[4];
            
            royaltyPercentage = setter[5];
            royaltyReceiver = royalityReciever; 

            platformVault = platformAddr;

            ipfsuri = _baseuri;

            transferOwnership(initializer);
    }

    function airdrop(address to, uint amount) external onlyOwner {
        inMint(to,amount);
    }

    function purchaseNft(address ref,uint amount) external payable {
        uint fee = saleSetting.mintFee * amount;
        require(msg.value >= fee,"Error: Insufficient Amount");
        require(msg.sender != ref, "Error: Refferal address cannot be self address.");

        if (!refferedAddress[ref][msg.sender]) {
            refferalCount[ref] += 1;
            refferedAddress[ref][msg.sender] = true;
        }

        if (ref != address(0)) {
            refferalFee[ref] += msg.value;
        }

        fundsraised += msg.value;
        inMint(msg.sender,amount);
    }

    function inMint(address to, uint amount) internal isLive() mintCompliance(amount) {
       for(uint i = 0; i < amount; i++) {
           uint currentSupply = totalSupply();
           uint nextId = currentSupply + 1;
            _safeMint(to, nextId);
            emit nftPurchase(to,nextId);
       }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return ipfsuri;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        return
            string(abi.encodePacked( ipfsuri, tokenId.toString(), ".json"));
    }

    // ERC-2981 royalty info function
    function royaltyInfo(uint256 tokenId, uint256 value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "ERC721: royalty for nonexistent token");

        royaltyAmount = (value * royaltyPercentage) / 100;
        return (royaltyReceiver, royaltyAmount);
    }

    function withdraw() external {
        if(fundsraised == 0) revert NoFundsAvailableForWithdraws();
        uint refPercent = saleSetting.RefFee;

        uint256 refFee = refPercent > 0
            ? (fundsraised * refPercent) / 100
            : 0;        

        uint amount = fundsraised - refFee;

        if(amount == adminWithdraw) revert NoFundsAvailableForWithdraws();
        uint256 available = amount - adminWithdraw;

        uint platform = available * platformCommission / 100;
        uint finalFee = available - platform;

        (bool s1, ) = payable(platformVault).call{value: platform}("");
        (bool s2, ) = payable(adminfeeWallet).call{value: finalFee}("");
        if(!s1) revert paymentFailed();
        if(!s2) revert paymentFailed();
        adminWithdraw = amount;
        emit fundsWithdraw(address(this),platformVault,platform);
        emit fundsWithdraw(address(this),adminfeeWallet,finalFee);
    }

    function withdrawReferral(address payable reciever) external {
        uint amount = refferalFee[msg.sender];
        uint withdrawn = refWithdraws[msg.sender];
        uint refPercent = saleSetting.RefFee;
        if(amount == 0) revert NoFundsAvailableForWithdraws();
        if(refPercent == 0) revert ReferralFeeDisabled();
        uint fee = ( amount * refPercent ) / 100;
        if(fee == withdrawn) revert NoFundsAvailableForWithdraws();
        uint available = fee - withdrawn;
        (bool s1,) = reciever.call{value: available}("");
        if(!s1) revert paymentFailed();
        refWithdraws[msg.sender] = fee;
        emit referralFundsWithdraw(msg.sender,reciever,available);
    }

    function availableRefEarnings(
        address user
    ) external view returns (uint256) {
        if (refferalFee[user] == 0) return 0;
        uint refPercent = saleSetting.RefFee;
        if(refPercent == 0) revert ReferralFeeDisabled();
        uint256 fee = (refferalFee[user] * refPercent) / 100;
        if (fee <= refWithdraws[user]) return 0;
        return fee - refWithdraws[user];
    }
    
    function changeAdminFeeWallet(address _wallet) external onlyOwner {
        adminfeeWallet = _wallet;
    }

    function setBaseUri(string memory _uri) external onlyOwner {
        ipfsuri = _uri;
    }

    // Function to set the royalty receiver and percentage
    function setRoyalties(address receiver, uint256 percentage) external onlyOwner {
        royaltyReceiver = receiver;
        royaltyPercentage = percentage;
    }

    function setMintFee(uint _newFee) external onlyOwner {
        saleSetting.mintFee = _newFee;
    }

    function updateTimer(uint _start, uint _end) external onlyOwner {
        if (block.timestamp > saleSetting.startTime)
            revert NftSaleAlreadyStarted();
        saleSetting.startTime = _start;
        saleSetting.EndTime = _end;
    }

}

contract factory is Ownable {

    uint public totalProjects;
    mapping (uint => address) public contractIndex;
    uint public contractFee;
    address public platformWallet;

    address public feeToken = 0xB18F98822C22492Bd6b77D19cae9367f3D60fcBf;
    uint public contractFeeToken;
    address public devWallet;

    event NewLisitng(address indexed _user, address indexed _contract,string _name, uint _index, uint _time);

    constructor(address _feeWallet) {  
        contractFee = 0.031 ether;
        platformWallet = _feeWallet;

        contractFeeToken = 100_000_000_000_000_000_000_000;
        devWallet = _feeWallet;
    }

    function launchContract(
            string memory name, 
            string memory symbol,
            uint[6] memory setter,
            address royalityReciever,
            string memory _baseuri,
            address feeWallet
    ) public payable {
        if(msg.value < contractFee) revert InsufficientFunds();
        NftContract contractAddress = new NftContract(
            name,
            symbol,
            setter,
            royalityReciever,
            _baseuri,
            feeWallet,
            msg.sender,
            platformWallet
        );
        totalProjects++;
        contractIndex[totalProjects] = address(contractAddress);
        uint remain = msg.value > contractFee 
            ? msg.value - contractFee
            : 0;
        if(remain > 0) {
            (bool os,) = payable(msg.sender).call{value: remain}("");
            if(!os) revert paymentFailed();
        }
        uint fee = msg.value -  remain;
        (bool os2,) = payable(platformWallet).call{value: fee}("");
        if(!os2) revert paymentFailed();
        emit NewLisitng(msg.sender, address(contractAddress), name, totalProjects, block.timestamp);
    }

    function launchContractFromToken(
            string memory name, 
            string memory symbol,
            uint[6] memory setter,
            address royalityReciever,
            string memory _baseuri,
            address feeWallet
    ) public {
        if (!IERC20(feeToken).transferFrom(msg.sender, devWallet, contractFeeToken)) {
            revert InsufficientFunds();
        }
        NftContract contractAddress = new NftContract(
            name,
            symbol,
            setter,
            royalityReciever,
            _baseuri,
            feeWallet,
            msg.sender,
            platformWallet
        );
        totalProjects++;
        contractIndex[totalProjects] = address(contractAddress);
        emit NewLisitng(msg.sender, address(contractAddress), name, totalProjects, block.timestamp);
    }
    
    function setFee(uint _newFee) external onlyOwner {
        contractFee = _newFee;
    }

    function setPlatformWallet(address _feeWallet) external onlyOwner {
        platformWallet = _feeWallet;
    }
    
    function setFeeToken(uint _newFeeToken) external onlyOwner {
        contractFeeToken = _newFeeToken;
    }
    
    function setFeeTokenAddress(address _newFeeToken) external onlyOwner {
        feeToken = _newFeeToken;
    }

    function setDevWallet(address _devWallet) external onlyOwner {
        devWallet = _devWallet;
    }

    function chainId() external view returns (uint) {
        return block.chainid;
    }

    function rescueFunds() external onlyOwner {
        (bool os,) = payable(msg.sender).call{value: address(this).balance}("");
        if(!os) revert paymentFailed();
    }

    function rescueTokens(address _token, uint _balance) external onlyOwner {
        (bool os,) = _token.call(abi.encodeWithSignature('transfer(address,uint)', msg.sender,_balance));
        if(!os) revert paymentFailed();
    }

    receive() external payable {}

}