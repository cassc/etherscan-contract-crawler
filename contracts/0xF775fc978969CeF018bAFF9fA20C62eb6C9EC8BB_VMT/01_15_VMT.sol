// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ERC721A.sol";
import "./extensions/ERC721AOwnersExplicit.sol";

// VMT
contract VMT is Ownable, ERC721A, ERC721AOwnersExplicit, ReentrancyGuard {
    using ECDSA for bytes32;
    using Strings for uint256;

    uint256 public immutable maxSupply = 10000;

    enum SalePhase {
        Locked,
        PreSale,
        PublicSale
    }
    SalePhase public phase = SalePhase.Locked;
    
    address private wlMintSigner;
    string private baseURL;
    string private placeholderURL;

    bool public usePlaceholder = true;

    // Mappings
    mapping(address => uint256) private wlMintAlreadyMint;

    constructor() ERC721A("VMT", "VMT") {
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if(usePlaceholder) {
            return placeholderURL;
        }

        return string(abi.encodePacked(baseURL, tokenId.toString()));
    }

    // Only I do the stuff
    function gifMe(uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= maxSupply, "reached max supply");
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(msg.sender, 1);
        }
    }

    function gifYou(address[] calldata addresses, uint256[] calldata count) external onlyOwner {
        uint256 len = addresses.length;
        for (uint256 i = 0; i < len; i++) {
            _safeMint(addresses[i], count[i]);
        }
    }

    //set signers
    function doDaWlThing(address _wlMintSigner)
        external
        onlyOwner
    {
        wlMintSigner = _wlMintSigner;
    }

    function mekItShowDaStuff(bool _usePlaceholder) public onlyOwner {
        usePlaceholder = _usePlaceholder;
    }

    function setTheWen(SalePhase phase_) external onlyOwner {
      phase = phase_;
    }

    function setTheWat(string calldata _baseURL) external onlyOwner {
      baseURL = _baseURL;
    }

    function setTheMaybe(string calldata _placeholderURL) external onlyOwner {
      placeholderURL = _placeholderURL;
    }

    function setFree() external onlyOwner {
      soulBound = false;
    }

    function isFreeSoGifMeNuthin() public onlyOwner {
      uint256 balance = address(this).balance;
      payable(msg.sender).transfer(balance);
    }

    // Mek da stuff
    function mekMachunForNeone()
      external
      payable
      callerIsUser
    {
        require(
            phase == SalePhase.PublicSale,
            "Public sale minting is not active"
        );
        require(
            1 + totalSupply() <= maxSupply,
            "Purchase would exceed max tokens"
        );

        _safeMint(msg.sender, 1);
    }

    function mekMachunForSpecial(bytes calldata signature)
        external
        payable
        callerIsUser
    {
        require(phase == SalePhase.PreSale,
          "Presale minting not active");
        require(
            1 + totalSupply() <= maxSupply,
            "Purchase would exceed max tokens"
        );
        require(
            wlMintSigner ==
                keccak256(
                    abi.encodePacked(
                        "\x19Ethereum Signed Message:\n32",
                        bytes32(uint256(uint160(msg.sender)))
                    )
                ).recover(signature),
            "Signer address mismatch."
        );

        require(wlMintAlreadyMint[msg.sender] == 0, "Already minted");

        wlMintAlreadyMint[msg.sender] = 1;
        _safeMint(msg.sender, 1);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override 
    {
        if(soulBound) {
            require(from == address(0), "Soul bound");
        }
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    // More boring stuff
    function setOwnersExplicit(uint256 quantity)
      external
      onlyOwner
      nonReentrant
    {
        _setOwnersExplicit(quantity);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    function tokensOfOwner(
        address _owner,
        uint256 startId,
        uint256 endId
    ) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index = 0;
            for (uint256 tokenId = startId; tokenId < endId; tokenId++) {
                if (index == tokenCount) break;

                if (ownerOf(tokenId) == _owner) {
                    result[index] = tokenId;
                    index++;
                }
            }

            return result;
        }
    }

    modifier callerIsUser() {
      require(tx.origin == msg.sender, "The caller is another contract");
      _;
    }
}