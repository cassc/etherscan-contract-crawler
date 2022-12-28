//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// @author: ElderPyke MellowLabs,LLC
import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Referable.sol";

//MellowPass is a project funding NFT mint that allows contributors to contribute to the seed round raises for MellowDefi
// Contributors are allowed to contribute up  to 3BNB,  and will be able to claim tokens on the launch of Lab Token


contract MellowPass is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    event Referral(address indexed _referrer, uint256 _quantity, uint256 _commission);

    string public baseURI = '';
    string public baseExtension = '.json';
    string public secret;

    
    uint256 public currentRaiseSupply = 1000;
    uint256 public finalRaiseSupply = 3000;
    uint256 public maxContribution = 12;
    uint256 public contributionAmount = 0.05 ether;

    uint8 public referralFee;

    address private address1;
    address private address2;
    address private address3;
    address crossmintAddress;


    bool public paused;
    bool public raiseOpen;
    bool private revealed;
    bool private referralOn;

    mapping(address => uint256) public walletMints;
    mapping(address => uint8) public referrers;
    event Received(address, uint256);

constructor(address _address1, address _address2, address _address3, address _crossmintAddress)
ERC721A("MellowPass", "mPass")
ReentrancyGuard(){
    address1 = _address1;
    address2 = _address2;
    address3 = _address3;
    crossmintAddress = _crossmintAddress;
}
modifier onlyAccounts() {
  require(tx.origin == msg.sender, "Mellow Pass :: Cannot be called by contract");
  _;
}

modifier onlyCrossmint() {
  require(crossmintAddress == msg.sender, "Unauthorized");
  _;
}

    receive() external payable {
        emit Received(msg.sender, msg.value);
  }

  function mint(address _to, address payable _referrer, uint256 _quantity) external payable nonReentrant onlyAccounts {
    require(!paused, "Contract is Paused");
    require(raiseOpen, "Raise is Currently Closed");
    require(msg.value >= _quantity * contributionAmount, "Insufficient BNB for Contribution");
    require(totalSupply() + _quantity <= currentRaiseSupply, "MellowPass :: Supply Limit Reached for This Round");
    require(_quantity > 0 && _quantity <= maxContribution, "Can't contribute more than allocated");
    require(walletMints[msg.sender] + _quantity <= maxContribution, "Exceeded Max Allocation per Wallet");

      walletMints[msg.sender] += _quantity;

      if(referralOn == true) {
          _mintTo(_to, _quantity, _referrer, msg.value);}
        else {
          _safeMint(_to, _quantity);
    }
  }

  function crossmint(address _to, uint256 _quantity, address payable _referrer) external payable nonReentrant onlyCrossmint {
    require(!paused, "Contract is Paused");
    require(raiseOpen, "Raise is Currently Closed");
    require(msg.value >= _quantity * contributionAmount, "Insufficient BNB for Contribution");
    require(totalSupply() + _quantity <= currentRaiseSupply, "MellowPass :: Supply Limit Reached for This Round");
    require(_quantity > 0 && _quantity <= maxContribution, "Can't contribute more than allocated");
     if(referralOn == true) {
          _mintTo(_to, _quantity, _referrer, msg.value);}
        else {
          _safeMint(_to, _quantity);
    }
  }

  function _mintTo (address _address, uint256 _quantity, address payable _referrer, uint256 _value) internal {
    _safeMint(_address, _quantity);
    _payReferral(_address, _referrer, _quantity, _value);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

   function tokenExist(uint256 id) external view returns (bool) {
        return _exists(id);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
        return secret; 
    }
    string memory currentBaseURI = _baseURI();
        
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), baseExtension))
        : '';  
    }

    function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

    function minted() external view returns (uint256) {
        return _totalMinted();
    } 

    function setCurrentRaiseSupply(uint256 _totalsupply) public onlyOwner {
    require(_totalsupply <= finalRaiseSupply && _totalsupply >= _totalMinted());
    currentRaiseSupply = _totalsupply;
  }

    function resetFinaRaiseSupply() public onlyOwner {
    finalRaiseSupply = currentRaiseSupply;
  }

    function setReferralFee(uint8 _percent) external onlyOwner {
        require(_percent <= 100, "Invalid fee");
        referralFee = _percent;
    }

    function setReferalBonus(uint8 _percent, address _referrer) external onlyOwner {
        require((_percent + referralFee) <= 100, "Invalid fee");
        referrers[_referrer] = _percent;
    }

     function _payReferral(address _recipient, address payable _referrer, uint256 _quantity, uint256 _value) internal {
        if (_referrer != address(0) && _referrer != _recipient) {
            uint256 _commission = _value * (referralFee + referrers[_referrer]) / 100;
            emit Referral(_referrer, _quantity, _commission);
            (bool sent,) = _referrer.call{value: _commission}("");
            require(sent, "Failed to send");
        }
    }

  function setParams(uint256 _contributionAmount, uint256 _maxContribution) external onlyOwner {
      contributionAmount = _contributionAmount;
      maxContribution = _maxContribution;
  }

  function setURIParams(string memory _tokenBaseURI, string memory _newBaseExtension) external onlyOwner {
      baseURI = _tokenBaseURI;
      baseExtension = _newBaseExtension;
  }

  function setSecret(string memory _secret) external onlyOwner {
    secret = _secret;
  }

  function setCrossmintAddress(address _crossmintAddress) public onlyOwner{
    crossmintAddress = _crossmintAddress;
  }

  function togglePaused() external onlyOwner {
      paused = !paused;
  }

  function toggleRaiseStatus() external onlyOwner {
      raiseOpen = !raiseOpen;
  }

  function toggleReferralStatus() external onlyOwner {
    referralOn = !referralOn;
  }

  function toggleReveal() external onlyOwner {
    revealed = !revealed;
  }

  function withdraw() external onlyOwner nonReentrant {
        uint256 amt1 = address(this).balance * 5 / 100;
        uint256 amt2 = address(this).balance * 5 / 100;
        uint256 amt3 = (address(this).balance - amt1 - amt2);

        ( bool success1, ) = address1.call{ value: amt1 }('');
        require( success1, 'withdraw failed to address1');

        ( bool success2, ) = address2.call{ value: amt2 }('');
        require( success2, 'withdraw failed to address2');

        ( bool success3, ) = address3.call{ value: amt3 }('');
        require( success3, 'withdraw failed to address3');

        (bool success, ) = payable(owner()).call{value: address(this).balance}('');
        require(success, 'withdraw failed');
    }
}