// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/*
1.1. The seller of the Lobstar subject to this smart contract (“Seller”) undertakes to sell or transfer
the Lobstar only on third party sites or platforms that support the sale of Ethereum-based
NFTs. 

1.2. The Seller must provide to the buyer of the Lobstar subject to this smart contract (“Buyer”):
- A written description of the Lobstar (in substantially similar form to that in the Terms of
used on www.thelobstars.com (“Terms”) at the time of the mint), and
- Details of the amount and payment method of the royalty of 7% (excluding any gas fees
and the commission applied by the relevant platform or marketplace which shall be
additionally charged) received by PopCorn Group Ltd on all secondary sales.

1.3. Buyer acquires or owns no intellectual property rights to the Lobstar.

1.4. Buyer of the Lobstar is granted an exclusive, limited license to the Lobstar and to any
underlying assets and benefits linked to the Lobstar, to use, display or store the Lobstar solely
for   their   personal,   non-commercial,   non-promotional   purposes,   or   for   communicating
ownership, or for purposes of secondary sales via any other marketplace or platform.

1.5. Buyer cannot use the Lobstar for any illegal or unauthorised purpose, including for any
unauthorised action as listed in the Terms.

1.6. Buyer and Seller acknowledge and agree that any commercial or other exploitation in breach
of the terms of this smart contract and/or the Terms may subject Buyer or Seller to claims of
intellectual property infringement. PopCorn Group Ltd. reserves the right to terminate or
suspend without notice Seller's or Buyer's use or ownership of, or rights in, the Lobstar in the
event of any breach of this smart contract or the Terms.
---
dev: bueno.art
*/

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Ticketed.sol";

error SaleInactive();
error SoldOut();
error InvalidPrice();
error InvalidQuantity();
error WithdrawFailed();
error InvalidSender();

contract Lobstars is ERC721A, Ownable, Ticketed {
    uint256 public price = 0.077 ether;

    // tokenIds will range from 1-7777
    uint256 public constant SUPPLY = 7777;
    uint256 public constant MAX_PER_TX = 6;

    string public _baseTokenURI;

    enum SaleState {
        CLOSED,
        ALLOWLIST,
        OPEN
    }

    SaleState public saleState = SaleState.CLOSED;

    address private dev = 0x985AFcA097414E5510c2C4faEbDb287E4F237A1B;
    address private lobstars = 0xFf0019e120d430015acc63f3F9CE6BdB131188eE;

    constructor(string memory baseURI) ERC721A("The Lobstars", "LOBS") {
        _baseTokenURI = baseURI;
    }

    function publicMint(uint256 amount) external payable {
        if (msg.sender != tx.origin) revert InvalidSender();
        if (amount > MAX_PER_TX) revert InvalidQuantity();
        if (saleState != SaleState.OPEN) revert SaleInactive();
        if (_currentIndex + (amount - 1) > SUPPLY) revert SoldOut();
        if (msg.value != price * amount) revert InvalidPrice();

        _safeMint(msg.sender, amount);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function mintAllowlist(
        bytes[] calldata _signatures,
        uint256[] calldata spotIds
    ) external payable {
        if (saleState != SaleState.ALLOWLIST) revert SaleInactive();
        if (_currentIndex + (spotIds.length - 1) > SUPPLY) revert SoldOut();
        if (msg.value != price * spotIds.length) revert InvalidPrice();

        for (uint256 i; i < spotIds.length; i++) {
            _claimAllowlistSpot(_signatures[i], spotIds[i]);
        }

        _safeMint(msg.sender, spotIds.length);
    }

    function devMint(address receiver, uint256 qty) external onlyOwner {
        if (_currentIndex + (qty - 1) > SUPPLY) revert InvalidQuantity();
        _safeMint(receiver, qty);
    }

    /**
     * @dev Sets sale state to CLOSED (0), ALLOWLIST (1), or OPEN (2).
     */
    function setSaleState(uint8 _state) public onlyOwner {
        saleState = SaleState(_state);
    }

    function setClaimGroups(uint256 num) external onlyOwner {
        _setClaimGroups(num);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdraw() external onlyOwner {
        (bool s1, ) = dev.call{value: (address(this).balance * 10) / 100}("");
        (bool s2, ) = lobstars.call{value: (address(this).balance)}("");

        if (!s1 || !s2) revert WithdrawFailed();
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function setSigner(address _signer) external onlyOwner {
        _setClaimSigner(_signer);
    }

    function tokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 holdingAmount = balanceOf(owner);
        uint256 currSupply = _currentIndex;
        uint256 tokenIdsIdx;
        address currOwnershipAddr;

        uint256[] memory list = new uint256[](holdingAmount);

        unchecked {
            for (uint256 i = _startTokenId(); i < currSupply; ++i) {
                TokenOwnership memory ownership = _ownerships[i];

                // Find out who owns this sequence
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }

                // Append tokens the last found owner owns in the sequence
                if (currOwnershipAddr == owner) {
                    list[tokenIdsIdx++] = i;
                }

                // All tokens have been found, we don't need to keep searching
                if (tokenIdsIdx == holdingAmount) {
                    break;
                }
            }
        }

        return list;
    }
}