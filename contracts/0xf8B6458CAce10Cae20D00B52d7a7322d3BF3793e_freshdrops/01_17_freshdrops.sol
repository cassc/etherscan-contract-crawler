// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

import "./ERC721A.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //      
//                                            .                                           //      
//                                           .++.                                         //      
//                                          :++++.                                        //      
//                                         -+++*++.                                       //      
//                                        -++++++++:                                      //      
//                                       =++++++++++:                                     //      
//                                      =++++++++++++-                                    //      
//                                     =++++++++++++++=                                   //      
//                                   .+++++++++++++++++=                                  //      
//                                  .++++++++++++++++++++.                                //     
//                                 :++++++++++++++++++++++.                               //      
//                                -++++++++++++++++++++++++:                              //      
//                               =++++++++++++++++++++++++++-                             //      
//                             .+++++++++++++++++++++++++++++=                            //      
//                             +++++++++++++++++++++++++++++++=                           //      
//                            -++++++++++++++++++++++++++++++++-                          //      
//                            ++++++++++++++++++++++++++++++++++                          //      
//                           .++++++++++++++++++++++++++++++++++                          //      
//                           .++++++++++++++++++++++++++++++++++                          //      
//                            +++++++++++++++++++++++++++++++++=                          //      
//                            :++++++++++++++++++++++++++++++++.                          //      
//                             -++++++++++++++++++++++++++++++:                           //      
//                              -++++++++++++++++++++++++++++:                            //      
//                               .=+++++++++++++++++++*++++=                              //      
//                                 .-++++++++++++++++++++-.                               //      
//                                    .-=++++++++++++=-.                                  //      
//                                         .::::::.                                       //      
//                                                                                        //      
//                                     .:..       ..:-.                                   //      
//                                      -++++***+++++:                                    //      
//                                       :++++++++++.                                     //      
//                                        .++++++++.                                      //      
//                                         .++++++                                        //      
//                                          .+++=                                         //      
//                                            +=                                          //      
//                                                                                        //      
////////////////////////////////////////////////////////////////////////////////////////////


contract freshdrops is ERC721A, Ownable, ReentrancyGuard, ERC2981, IERC1155Receiver {
    using Strings for uint256;
    using SafeMath for uint256;

    uint256 public passId;

    uint256 public constant MAX_SUPPLY = 500;
    uint256 public tokenPrice = .39 ether;
    string public baseURIExtended = "https://metadata.freshdrops.workers.dev/?id=";
    string public extension = "";
    bool public claimActive = false;
    uint96 public tokenRoyalties = 1000; // 10% royalty

    address royaltyPayout = 0xB2AEcc6424F0d6f61533A05373ea88D3CcA8aC6a; // TODO: change

    mapping(address => uint256) public passesReceived;
    mapping(address => uint256) public passesToMint;

    constructor() ERC721A("freshdrops", "freshdrops") {
        _safeMint(owner(), 1); // one to initialize the contract
        _setDefaultRoyalty(royaltyPayout, tokenRoyalties); // set intial default royalties
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "FD: The caller is another contract");
        _;
    }

    function setPassId(uint256 _id) external onlyOwner {
        passId = _id;
    }

    function openClaim() external onlyOwner {
        claimActive = true;
    }

    function closeClaim() external onlyOwner {
        claimActive = false;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURIExtended = _uri;
    }

    function setTokenPrice(uint256 _newPrice) external onlyOwner {
        tokenPrice = _newPrice;
    }

    function setExtension(string memory _extension) external onlyOwner {
        extension = _extension;
    }

    function mint(uint256 amount) external payable callerIsUser nonReentrant {
        require(claimActive, "FD: Sale is not active");
        require(amount > 0, "FD: Must attempt to mint at least 1 token");
        require(
            passesToMint[msg.sender] > 0,
            "FD: Have not deposited any OG passes to claim"
        );
        require(
            passesToMint[msg.sender] >= amount,
            "FD: Deposited balance is less than quantity trying to mint"
        );
        require(
            totalSupply() + amount <= MAX_SUPPLY,
            "FD: Purchase would exceed MAX_SUPPLY"
        );
        require(tokenPrice * amount == msg.value, "FD: Incorrect ETH value specified");

        _safeMint(msg.sender, amount);
        if(amount > passesToMint[msg.sender]){
            passesToMint[msg.sender] = 0;
        } else {
            passesToMint[msg.sender] -= amount;
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        require(_exists(tokenId), "FD: Token does not exist");

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, tokenId.toString(), extension)
                )
                : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURIExtended;
    }

    // WITHDRAW

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "FD: Nothing to withdraw");

        require(payable(msg.sender).send(address(this).balance));
    }

    // ROYALTIES

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, ERC2981, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setTokenRoyalties(uint96 _royalties) external onlyOwner {
        tokenRoyalties = _royalties;
        _setDefaultRoyalty(royaltyPayout, tokenRoyalties);
    }

    function setRoyaltyPayoutAddress(address _payoutAddress)
        external
        onlyOwner
    {
        royaltyPayout = _payoutAddress;
        _setDefaultRoyalty(royaltyPayout, tokenRoyalties);
    }

    // 1155 RECEIVER

    function onERC1155Received(
        address,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata
    ) external override returns (bytes4) {
        if(_id == passId){
            incrementPass(_from, _value);
            
        }        

        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"
                )
            );
    }

    // PASS SETTING

    function incrementPass(address _addr, uint256 _val) internal {
        passesReceived[_addr] += _val;
    }

    function validatePass(address _addr, uint256 _val) external onlyOwner{
        require(passesReceived[_addr] > 0, "FD: No passes to validate for this address");
        require(passesReceived[_addr] >= _val, "FD: Not enough passes received to validate");
        passesToMint[_addr] += _val;
        if(_val > passesReceived[_addr]){
            passesReceived[_addr] -= 0;
        } else {
            passesReceived[_addr] -= _val;
        }
    }
}