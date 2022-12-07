// SPDX-License-Identifier: UNLICENSED

/*

 ▄▀▀▀█▄    ▄▀▀▄▀▀▀▄  ▄▀▀█▄▄▄▄  ▄▀▀█▄▄▄▄                                              
█  ▄▀  ▀▄ █   █   █ ▐  ▄▀   ▐ ▐  ▄▀   ▐                                              
▐ █▄▄▄▄   ▐  █▀▀█▀    █▄▄▄▄▄    █▄▄▄▄▄                                               
 █    ▐    ▄▀    █    █    ▌    █    ▌                                               
 █        █     █    ▄▀▄▄▄▄    ▄▀▄▄▄▄                                                
█         ▐     ▐    █    ▐    █    ▐                                                
▐                    ▐         ▐                                                     
 ▄▀▀█▄   ▄▀▀▀▀▄    ▄▀▀▀▀▄                                                            
▐ ▄▀ ▀▄ █    █    █    █                                                             
  █▄▄▄█ ▐    █    ▐    █                                                             
 ▄▀   █     █         █                                                              
█   ▄▀    ▄▀▄▄▄▄▄▄▀ ▄▀▄▄▄▄▄▄▀                                                        
▐   ▐     █         █                                                                
          ▐         ▐                                                                
 ▄▀▀█▄▄▄▄  ▄▀▀▀█▀▀▄  ▄▀▀█▄▄▄▄  ▄▀▀▄▀▀▀▄  ▄▀▀▄ ▀▄  ▄▀▀█▄   ▄▀▀▀▀▄    ▄▀▀▀▀▄  ▄▀▀▄ ▀▀▄ 
▐  ▄▀   ▐ █    █  ▐ ▐  ▄▀   ▐ █   █   █ █  █ █ █ ▐ ▄▀ ▀▄ █    █    █    █  █   ▀▄ ▄▀ 
  █▄▄▄▄▄  ▐   █       █▄▄▄▄▄  ▐  █▀▀█▀  ▐  █  ▀█   █▄▄▄█ ▐    █    ▐    █  ▐     █   
  █    ▌     █        █    ▌   ▄▀    █    █   █   ▄▀   █     █         █         █   
 ▄▀▄▄▄▄    ▄▀        ▄▀▄▄▄▄   █     █   ▄▀   █   █   ▄▀    ▄▀▄▄▄▄▄▄▀ ▄▀▄▄▄▄▄▄▀ ▄▀    
 █    ▐   █          █    ▐   ▐     ▐   █    ▐   ▐   ▐     █         █         █     
 ▐        ▐          ▐                  ▐                  ▐         ▐         ▐     
 ▄▀▀█▄▄   ▄▀▀█▄▄▄▄  ▄▀▀▀▀▄    ▄▀▀▀▀▄   ▄▀▀▄ ▄▀▀▄  ▄▀▀█▄▄▄▄  ▄▀▀█▄▄                   
▐ ▄▀   █ ▐  ▄▀   ▐ █    █    █      █ █   █    █ ▐  ▄▀   ▐ █ ▄▀   █                  
  █▄▄▄▀    █▄▄▄▄▄  ▐    █    █      █ ▐  █    █    █▄▄▄▄▄  ▐ █    █                  
  █   █    █    ▌      █     ▀▄    ▄▀    █   ▄▀    █    ▌    █    █                  
 ▄▀▄▄▄▀   ▄▀▄▄▄▄     ▄▀▄▄▄▄▄▄▀ ▀▀▀▀       ▀▄▀     ▄▀▄▄▄▄    ▄▀▄▄▄▄▀                  
█    ▐    █    ▐     █                            █    ▐   █     ▐                   
▐         ▐          ▐                            ▐        ▐                         
 ▄▀▀▀▀▄    ▄▀▀▀▀▄   ▄▀▀▄▀▀▀▄  ▄▀▀█▄▄▄▄                                               
█    █    █      █ █   █   █ ▐  ▄▀   ▐                                               
▐    █    █      █ ▐  █▀▀█▀    █▄▄▄▄▄                                                
    █     ▀▄    ▄▀  ▄▀    █    █    ▌                                                
  ▄▀▄▄▄▄▄▄▀ ▀▀▀▀   █     █    ▄▀▄▄▄▄                                                 
  █                ▐     ▐    █    ▐                                                 
  ▐                           ▐                                                      


by Wumbo Labs
*/

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { DefaultOperatorFilterer, OperatorFilterer } from "./opensea/DefaultOperatorFilterer.sol";
import "./ERC721A.sol";
import "./ERC721ABurnable.sol";
import "./ERC721AQueryable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract FAEBLFIGHTER is ERC721A, ERC721ABurnable, ERC721AQueryable, Ownable, ERC2981, DefaultOperatorFilterer {
    using Strings for uint256;

    uint256 constant maxSupply = 5000;
    uint256 constant mintPrice = 0 ether;
    uint256 constant donationSecondMintPrice = 0.025 ether;
    uint256 constant meritEffortSecondMintPrice = 0.05 ether;
    uint256 public maxPerAddressMarathon = 2;
    uint256 public maxPerAddressWaitlistPublic = 1;
    string public baseURI = "https://ipfs.filebase.io/ipfs/Qma9smRfR97BA1d1UiQfEPwRpeb5UMrWJyoogmB5is2hPX";
    string public baseExtension = "";

    bytes32 public wumboRoot = 0xd1b1517f30eae52754b69fd67ea323bf0258219dcbcc14ba5409cb2560556875;
    bytes32 public donationRoot = 0x6e7b6e3f329e03295d2f955474f013b79c0d943e4b7dfeac92b394dc422b3b67;
    bytes32 public meritEffortRoot = 0x55e5325145fab893d09925b1d98a4d1027a235c59a52d06e8fdf209822b0b780;
    bytes32 public collabLotteryRoot = 0xe70c7fc4224222c8424aa9a41c1864cd54f45caec0fd23afe38e26f26f280a7b;
    bytes32 public waitlistRoot = 0x5474a5fa3766d4dd7788889f94f65001ed0914b5461eba5ce2d0abf3e4eaad2e;

    enum Status {
        FIGHTERS_READY,
        MARATHON,
        WAITLIST,
        PUBLIC,
        QUEUE_UP,
        REVEAL
    }

    Status public state;

    constructor() ERC721A("FAEBLFIGHTER", "FAEBL") {
    }
    
    function getNumberMinted(address _address) external view returns(uint256) {
      return _numberMinted(_address);
    }

    function setState(Status _state) external onlyOwner {
        state = _state;
    }
    
    function isWumbo(address sender, bytes32[] calldata proof) public view returns(bool) {
        return MerkleProof.verify(proof, wumboRoot, keccak256(abi.encodePacked(sender)));
    }

    function isDonation(address sender, bytes32[] calldata proof) public view returns(bool) {
        return MerkleProof.verify(proof, donationRoot, keccak256(abi.encodePacked(sender)));
    }

    function isMeritEffort(address sender, bytes32[] calldata proof) public view returns(bool) {
        return MerkleProof.verify(proof, meritEffortRoot, keccak256(abi.encodePacked(sender)));
    }

    function isCollabLottery(address sender, bytes32[] calldata proof) public view returns(bool) {
      return MerkleProof.verify(proof, collabLotteryRoot, keccak256(abi.encodePacked(sender)));
    }

    function isWaitlist(address sender, bytes32[] calldata proof) public view returns(bool) {
        return MerkleProof.verify(proof, waitlistRoot, keccak256(abi.encodePacked(sender)));
    }

    function mintMarathon(bytes32[] calldata proof, uint256 amount) public payable {
      require(state == Status.MARATHON, "FAEBL: Marathon mint not started");
      bool isOnDonation = isDonation(msg.sender, proof);
      bool isOnMeritEffort = isMeritEffort(msg.sender, proof);
      bool isOnCollabLottery = isCollabLottery(msg.sender, proof);
      bool isOnWumbo = isWumbo(msg.sender, proof);
      require(isOnWumbo || isOnDonation || isOnMeritEffort || isOnCollabLottery, "FAEBL: Cannot mint marathon");
      require(amount + totalSupply() <= maxSupply, "FAEBL: Max supply exceeded");
      require(_numberMinted(msg.sender) + amount <= maxPerAddressMarathon, "FAEBL: Exceeded total amount per address");
      uint256 mintedAmount = _numberMinted(msg.sender);
      if (isOnCollabLottery) {
        require(_numberMinted(msg.sender) < 1 && amount == 1, "FAEBL: Collab & Lottery can only mint 1 per address");
      } else if (mintedAmount > 0 && isOnDonation) {
        require(msg.value == donationSecondMintPrice, "FAEBL: Not enough for second mint for donation");
      } else if (mintedAmount > 0 && isOnMeritEffort) {
        require(msg.value == meritEffortSecondMintPrice, "FAEBL: Not enough for second mint for donation");
      }
      _safeMint(msg.sender, amount);
    }

    function mintWaitlist(bytes32[] calldata proof, uint256 amount) public payable {
      require(state == Status.WAITLIST, "FAEBL: Waitlist mint not started");
      require(isWaitlist(msg.sender, proof), "FAEBL: Cannot mint waitlist");
      require(amount + totalSupply() <= maxSupply, "FAEBL: Max supply exceeded");
      require(_numberMinted(msg.sender) < 1 && _numberMinted(msg.sender) + amount <= maxPerAddressWaitlistPublic, "FAEBL: Exceeded total amount per address");
      _safeMint(msg.sender, amount);
    }

    function mintPublic(uint256 amount) public payable {
      require(state == Status.PUBLIC, "FAEBL: Public mint not started");
      require(amount + totalSupply() <= maxSupply, "FAEBL: Max supply exceeded");
      require(_numberMinted(msg.sender) + amount <= maxPerAddressWaitlistPublic, "FAEBL: Exceeded total amount per address");
      _safeMint(msg.sender, amount);
    }

    function mintDev(address _address, uint256 _quantity) external onlyOwner {
      require(totalSupply() + _quantity <= maxSupply, "FAEBL: Exceeds total supply");
      _safeMint(_address, _quantity);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A, IERC721A)
        returns (string memory)
    {
        require(
        _exists(tokenId),
        "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        if (state != Status.REVEAL) {
          return currentBaseURI;
        }

        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)) : "";
    }

      function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721A, ERC2981, IERC721A)
        returns (bool) 
    {
        return
            ERC2981.supportsInterface(interfaceId)
            || ERC721A.supportsInterface(interfaceId);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setWumboRoot(bytes32 _newRoot) public onlyOwner {
      wumboRoot = _newRoot;
    }

    function setDonationRoot(bytes32 _newRoot) public onlyOwner {
      donationRoot = _newRoot;
    }

    function setMeritEffortRoot(bytes32 _newRoot) public onlyOwner {
      meritEffortRoot = _newRoot;
    }

    function setCollabLotteryRoot(bytes32 _newRoot) public onlyOwner {
      collabLotteryRoot = _newRoot;
    }

    function setWaitlistRoot(bytes32 _newRoot) public onlyOwner {
      waitlistRoot = _newRoot;
    }

    function setDefaultRoyalty(
      address _receiver,
      uint96 _feeNumerator
    )
      external
      onlyOwner
    {
      _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function deleteDefaultRoyalty()
      external
      onlyOwner
    {
      _deleteDefaultRoyalty();
    }

    function setTokenRoyalty(
      uint256 _tokenId,
      address _receiver,
      uint96 _feeNumerator
    )
      external
      onlyOwner
    {
      _setTokenRoyalty(_tokenId, _receiver, _feeNumerator);
    }

    function resetTokenRoyalty(
      uint256 tokenId
    )
      external
      onlyOwner
    {
      _resetTokenRoyalty(tokenId);
    }

    /* ------------ OpenSea Overrides --------------*/
    function transferFrom(
      address _from,
      address _to,
      uint256 _tokenId
    )
      public
      payable
      override(ERC721A, IERC721A)  
      onlyAllowedOperator(_from)
    {
        super.transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(
      address _from,
      address _to,
      uint256 _tokenId
    ) 
      public
      payable
      override(ERC721A, IERC721A) 
      onlyAllowedOperator(_from)
    {
      super.safeTransferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(
      address _from,
      address _to,
      uint256 _tokenId,
      bytes memory _data
    )
      public
      payable
      override(ERC721A, IERC721A) 
      onlyAllowedOperator(_from)
    {
      super.safeTransferFrom(_from, _to, _tokenId, _data);
    }

    function withdrawMoney() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdraw failed.");
    }
}