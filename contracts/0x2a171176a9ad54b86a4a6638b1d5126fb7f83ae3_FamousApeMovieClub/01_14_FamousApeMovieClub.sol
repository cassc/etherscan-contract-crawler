// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract FamousApeMovieClub is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public constant MAXSUPPLY = 5555;
    uint256 public constant MAX_SELF_MINT = 10;

    address private signerAddress = 0x454359b0ba79eEC5331dE58077AF2B2b2576639F;
    address public mainAddress = 0x29Be76B28B5E1BcEfd2A04428417b99f2e402960;
    string public baseURI;

    enum WorkflowStatus {
        Before,
        Presale,
        Sale,
        SoldOut
    }


    WorkflowStatus public workflow;


    constructor(
        string memory _initBaseURI
    ) ERC721("FamousApeMovieClub", "FAMC") {
        workflow = WorkflowStatus.Before;
        setBaseURI(_initBaseURI);
    }

    //GETTERS

    function publicSaleLimit() public pure returns (uint256) {
        return MAXSUPPLY;
    }

    function getSaleStatus() public view returns (WorkflowStatus) {
        return workflow;
    }

   function hashMessage(address sender) private pure returns (bytes32) {
        return keccak256(abi.encode(sender));
    }

   function isValidData(bytes32 message,bytes memory sig) private
        view returns (bool) {
        return (recoverSigner(message, sig) == signerAddress);
    }



    function recoverSigner(bytes32 message, bytes memory sig)
       public
       pure
       returns (address)
        {
       uint8 v;
       bytes32 r;
       bytes32 s;

       (v, r, s) = splitSignature(sig);
       return ecrecover(message, v, r, s);
        }

   function splitSignature(bytes memory sig)
       public
       pure
       returns (uint8, bytes32, bytes32)
    {
       require(sig.length == 65);
       
       bytes32 r;
       bytes32 s;
       uint8 v;

       assembly {
           // first 32 bytes, after the length prefix
           r := mload(add(sig, 32))
           // second 32 bytes
           s := mload(add(sig, 64))
           // final byte (first byte of the next 32 bytes)
           v := byte(0, mload(add(sig, 96)))
       }

       return (v, r, s);
    }


    function presaleMint(bytes32 messageHash, bytes calldata signature, uint256 ammount)
    external
    payable
    nonReentrant
    {

        uint256 price = 0.08 ether;
        require(workflow == WorkflowStatus.Presale, "FamousApe: Presale is not started yet!");
        require(ammount <= 10, "FamousApe: Presale mint is one token only.");
        require(msg.value >= price * ammount, "INVALID_PRICE");
        require(hashMessage(msg.sender) == messageHash, "MESSAGE_INVALID");
        require(
            isValidData(messageHash, signature),
            "SIGNATURE_VALIDATION_FAILED"
        );
        uint256 initial = 0;
        for (uint256 i = initial; i < ammount; i++) {
            _safeMint(msg.sender, totalSupply());
        }
    }

    function publicSaleMint(uint256 ammount) public payable nonReentrant {
        uint256 price = 0.12 ether;
        require(workflow != WorkflowStatus.SoldOut, "FamousApe: SOLD OUT!");
        require(workflow == WorkflowStatus.Sale, "FamousApe: public sale is not started yet");
        require(msg.value >= price * ammount, "FamousApe: Insuficient funds");
        require(ammount <= 10, "FamousApe: You can only mint up to 10 token at once!");
        for (uint256 i = 0; i < ammount; i++) {
            _safeMint(msg.sender, totalSupply());
        }
    }


    // Before All.

    function setUpPresale() external onlyOwner {
        workflow = WorkflowStatus.Presale;
    }
    function setUpBeforesale() external onlyOwner {
        workflow = WorkflowStatus.Before;
    }
    function setUpSale() external onlyOwner {
        require(workflow == WorkflowStatus.Presale, "FamousApe: Unauthorized Transaction");
        workflow = WorkflowStatus.Sale;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }


    function setSignerAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "CAN'T PUT 0 ADDRESS");
        signerAddress = _newAddress;
    }

  
     function withdrawAll() public payable onlyOwner {
        uint256 mainadress_balance = address(this).balance;
        require(payable(mainAddress).send(mainadress_balance));
    }
    function changeWallet(address _newwalladdress) external onlyOwner {
        mainAddress = _newwalladdress;
    }

    // FACTORY
  
    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
                : "";
    }

}