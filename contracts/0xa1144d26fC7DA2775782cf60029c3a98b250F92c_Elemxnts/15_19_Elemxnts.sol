//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                ..                                                                                                            //
//       ..::?G&@@@@@@5   .?.             ..:^JG&@@@@@@?     .7        :JJ:                  :YY^    .7               ~7!!!!7JYPB#&&@@@&~      .:^!?JYYY?!.     //
//   Y&@@@@@@@@@@@&BY:  [email protected]@#          P&@@@@@@@@@@@&BJ.    [email protected]@&.     [email protected]@@@.     ?&&B?:    [email protected]@@@:  [email protected]@&~       ^?7  #@@@@@@@@@@@@@@@@@@G .!5B&@@@@@@@@@@@&      //
//   :@@@@@@BPJ!^.       ^@@&         [email protected]@@@@@B5?!:.        [email protected]@@@@.   [email protected]@@@@~     [email protected]@@@@&Y?&@@@@@!   [email protected]@@@P     :@@@B Y#&@@@@@@@@@&J?!^!G#@@@@@@@@&&&#B#&&@Y     //
//   [email protected]@@@@!.:~?5GB#&5   [email protected]@P         :@@@@&^.^!J5G#&#J    [email protected]@@@@&  [email protected]@@@@@G      [email protected]@@@@@@@@@B.    [email protected]@@@@&:   [email protected]@@@^    [email protected]@@@&.   ^@@@@@@@@&BGY?~:.          //
//   &@@@@@@@@@@@@@@P   [email protected]@!         [email protected]@@@@@@@@@@@@@@Y   [email protected]@@@@@@[email protected]@@#@@@@        [email protected]@@@@@@#      &@@@@@@@?   &@@@5      ^@@@@J    [email protected]@@@@@@@@@@@@@@@@#5:       //
//   &@@@@@&&#G5J~:    [email protected]@@.          @@@@@@&&#G5?~.     [email protected]@@^[email protected]@@@@@~ &@@@!       [email protected]@@@@@@@@J    @@@@7&@@@B  &@@@?      [email protected]@@@7     .^[email protected]@@@@~      //
//   [email protected]@@@@!   .:!JG&&? [email protected]@&          [email protected]@@@@^   .:!YG&&~ :@@@B  &@@@@Y  [email protected]@@B     :[email protected]@@@&[email protected]@@@&^ :@@@#  #@@@&[email protected]@@@.      [email protected]@@@7                .^7&@@@@#:     //
//   @@@@@@#B#&@@@@@@@B &@@B:!YG#&@@[email protected]@@@@@#B#@@@@@@@@P [email protected]@@:  [email protected]@@&   ^@@@@.  ^[email protected]@@@@J    [email protected]@@@^^@@@&   [email protected]@@@@@@Y       &@@@@7         :!YG#&@@@@@@@G^       //
//   [email protected]@@@@@@@@@@&P7. [email protected]@@@@@@@@@#7  [email protected]@@@@@@@@@@#5!. ^@@@#    [email protected]@?    [email protected]@@: [email protected]@@@@B.       :P&@5 &@@@    :[email protected]@@@?        &@@@@7      [email protected]@@@@@@@@@&G!.          //
//   [email protected]@@&BY!:       #@@@@&BY~.      [email protected]@@&GY~:      [email protected]@#^     !7      P&J  ~&@@@?            .  :&@&.     ~GY.         [email protected]@@@^      [email protected]@@@@&#P?:                //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*   Created with love for the Pxin Gxng, by Rxmmy  */
/*   Special thank you to xtremetom for all of the incredible help and advice <3   */

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "operator-filter-registry/src/UpdatableOperatorFilterer.sol";
import "operator-filter-registry/src/RevokableDefaultOperatorFilterer.sol";

/**
 * @title Elemxnts
 * @author Rammy
 * @notice Explore GxngYxng's take on the natural world in his classic PFP style.
 */
contract Elemxnts is
    ERC1155Supply,
    Ownable,
    ERC2981,
    RevokableDefaultOperatorFilterer
{
    using BitMaps for BitMaps.BitMap;

    string public website = "https://ghxsts.com";
    string public constant name_ = "Elemxnts";
    string public constant symbol_ = "ELEMXNTS";
    uint256 public mintPrice = .06 ether;
    uint256 public waitlistMintPrice = .12 ether;

    event PermanentURI(string _value, uint256 indexed _id);

    bool public Frozen;
    bool public saleOpen;
    bool public waitlistSaleOpen;
    bytes32 public merkleRoot;

    struct MINT {
        uint256 id; // ID of the Elemxnt to mint
        uint256 qty; // How many
    }

    struct Elemxnt {
        string metadataURI;
        uint256 maxSupply;
    }

    mapping(uint256 => Elemxnt) public ELEMXNTS;

    // Address => Minted?
    BitMaps.BitMap minted;
    BitMaps.BitMap waitlistMinted;

    constructor(Elemxnt[] memory els) ERC1155("ipfs://") {
        createElemxnts(els);
        _setDefaultRoyalty(msg.sender, 1000);
    }

    /**
     * @notice Create the elemxnts.
     * @param els An array of ELEMXNT structs.
     */
    function createElemxnts(Elemxnt[] memory els) internal {
        uint256 i;
        unchecked {
            do {
                ELEMXNTS[i] = els[i];
            } while (++i < els.length);
        }
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    /**
     * @notice Mint a set of elemxnts as the owner.
     * @param _to The wallet address to mint to.
     * @param mintData An array of MINT structs to mint.
     */
    function ownerMint(
        address _to,
        MINT[] calldata mintData
    ) external onlyOwner {
        uint256 i;
        unchecked {
            do {
                require(!Frozen, "Frozen");
                require(
                    ELEMXNTS[mintData[i].id].maxSupply > 0,
                    "Elemxnt does not exist"
                );
                require(
                    totalSupply(mintData[i].id) + mintData[i].qty <=
                        ELEMXNTS[mintData[i].id].maxSupply,
                    "Max supply reached"
                );
                _mint(_to, mintData[i].id, mintData[i].qty, "");
            } while (++i < mintData.length);
        }
    }

    /**
     * @notice Waitlist minting.
     * @param mintData An array of MINT structs to mint.
     * @param merkleProof The merkle proof.
     */
    function waitlistMint(
        MINT[] calldata mintData,
        bytes32[] calldata merkleProof
    ) external payable callerIsUser {
        require(waitlistSaleOpen, "Sale not started");
        uint256 len = mintData.length;
        require(len < 3, "Maximum two mints allowed");
        require(!waitlistMinted.get(uint160(msg.sender)), "Already minted");
        require(!Frozen, "Frozen");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, leaf),
            "Invalid proof"
        );

        uint256 totalPrice;
        uint256 i;
        uint256 id;
        uint256 qty;
        uint256 maxSupply;
        unchecked {
            do {
                id = mintData[i].id;
                qty = mintData[i].qty;
                maxSupply = ELEMXNTS[id].maxSupply;

                require(maxSupply > 0, "Elemxnt does not exist");
                require(
                    totalSupply(id) + qty <= maxSupply,
                    "Max supply reached"
                );
                require(qty == 1, "Can only mint one");

                totalPrice += waitlistMintPrice * qty;
            } while (++i < len);
        }

        // verify amount paid is sufficient
        require(msg.value == totalPrice, "Incorrect ETH amount");

        // track the address that minted
        waitlistMinted.set(uint160(msg.sender));

        i = 0;
        unchecked {
            do {
                id = mintData[i].id;
                qty = mintData[i].qty;

                if (qty > 0) _mint(msg.sender, id, qty, "");
            } while (++i < len);
        }
    }

    /**
     * @notice Allowlist minting.
     * @param mintData An array of MINT structs to mint.
     * @param merkleProof The merkle proof.
     * @param ticket The ticket.
     */
    function allowlistMint(
        MINT[] calldata mintData,
        bytes32[] calldata merkleProof,
        uint256[] calldata ticket
    ) external payable callerIsUser {
        require(saleOpen, "Sale not started");
        uint256 len = mintData.length;
        require(len == ticket.length, "Invalid mint request");
        require(!minted.get(uint160(msg.sender)), "Already minted");
        require(!Frozen, "Frozen");

        // save gas and check sig validity early
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, ticket));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, leaf),
            "Invalid proof"
        );

        uint256 totalPrice;
        uint256 i;
        uint256 id;
        uint256 qty;
        uint256 maxSupply;
        unchecked {
            do {
                id = mintData[i].id;
                qty = mintData[i].qty;
                maxSupply = ELEMXNTS[id].maxSupply;

                require(maxSupply > 0, "Elemxnt does not exist");
                require(
                    totalSupply(id) + qty <= maxSupply,
                    "Max supply reached"
                );
                require(qty <= ticket[i], "Exceeds allocation");

                totalPrice += mintPrice * qty;
            } while (++i < len);
        }

        // verify amount paid is sufficient
        require(msg.value == totalPrice, "Incorrect ETH amount");

        // track the address that minted
        minted.set(uint160(msg.sender));

        i = 0;
        unchecked {
            do {
                id = mintData[i].id;
                qty = mintData[i].qty;

                if (qty > 0) _mint(msg.sender, id, qty, "");
            } while (++i < len);
        }
    }

    /**
     * @notice Update the URI for a given elemxnt
     * @param id The ID of the elemxnt to update
     * @param _uri The new URI
     */
    function updateURI(uint256 id, string calldata _uri) external onlyOwner {
        require(!Frozen, "Frozen");
        require(ELEMXNTS[id].maxSupply > 0, "Elemxnt does not exist");
        ELEMXNTS[id].metadataURI = _uri;
    }

    /**
     * @notice Update the mint price.
     * @param price The new price.
     */
    function updateMintPrice(uint256 price) external onlyOwner {
        mintPrice = price;
    }

    /**
     * @notice Update the mint price.
     * @param price The new price.
     */
    function updateWaitlistMintPrice(uint256 price) external onlyOwner {
        waitlistMintPrice = price;
    }

    /**
     * @notice Toggle the sale.
     */
    function toggleSale() external onlyOwner {
        saleOpen = !saleOpen;
    }

    /**
     * @notice Toggle the waitlist sale.
     */
    function toggleWaitlistSale() external onlyOwner {
        waitlistSaleOpen = !waitlistSaleOpen;
    }

    /**
     * @notice Set the website url.
     * @param url The new url.
     */
    function setWebsite(string calldata url) external onlyOwner {
        website = url;
    }

    /**
     * @notice Set the merkle root.
     * @param _merkleRoot The new merkle root.
     */
    function updateMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    // Permanently freeze metadata and minting functions.

    function freeze() external onlyOwner {
        Frozen = true;
        emit PermanentURI(ELEMXNTS[0].metadataURI, 0);
        emit PermanentURI(ELEMXNTS[1].metadataURI, 1);
        emit PermanentURI(ELEMXNTS[2].metadataURI, 2);
        emit PermanentURI(ELEMXNTS[3].metadataURI, 3);
        emit PermanentURI(ELEMXNTS[4].metadataURI, 4);
        emit PermanentURI(ELEMXNTS[5].metadataURI, 5);
        emit PermanentURI(ELEMXNTS[6].metadataURI, 6);
        emit PermanentURI(ELEMXNTS[7].metadataURI, 7);
        emit PermanentURI(ELEMXNTS[8].metadataURI, 8);
        emit PermanentURI(ELEMXNTS[9].metadataURI, 9);
        emit PermanentURI(ELEMXNTS[9].metadataURI, 10);
        emit PermanentURI(ELEMXNTS[9].metadataURI, 11);
        emit PermanentURI(ELEMXNTS[9].metadataURI, 12);
        emit PermanentURI(ELEMXNTS[9].metadataURI, 13);
        emit PermanentURI(ELEMXNTS[9].metadataURI, 14);
        emit PermanentURI(ELEMXNTS[9].metadataURI, 15);
    }

    /**
     * @notice Get the metadata uri for a specific Elemxnt.
     * @param id The Elemxnt to return metadata for.
     * @return metadataURI URI for the Elemxnt.
     */
    function uri(uint256 id) public view override returns (string memory) {
        require(exists(id), "URI: nonexistent token");

        return ELEMXNTS[id].metadataURI;
    }

    // ** - ADMIN - ** //
    /**
     * @notice Withdraw ETH from the contract.
     * @param _to The address to send the ETH to.
     * @param _amount The amount of ETH to send.
     */
    function withdrawEther(
        address payable _to,
        uint256 _amount
    ) external onlyOwner {
        _to.transfer(_amount);
    }

    /**
     * @notice Withdraw all ETH from the contract.
     * @param _to The address to send the ETH to.
     */
    function withdrawAll(address payable _to) external onlyOwner {
        _to.transfer(address(this).balance);
    }

    /**
     * @notice Give approval to an operator to transfer all tokens on behalf of the caller. Cannot be called by a filtered operator.
     * @param operator The address to give approval to.
     * @param approved True if the operator is approved, false to revoke approval.
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @notice Transfer a token from one address to another.
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param tokenId The token ID to transfer.
     * @param amount The amount to transfer.
     * @param data The data to pass to the receiver.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    /**
     * @notice Transfer multiple tokens from one address to another.
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param ids The token IDs to transfer.
     * @param amounts The amounts to transfer.
     * @param data The data to pass to the receiver.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @notice Override. Check if contract supports interface.
     * @param interfaceId The interface to check.
     * @return bool If the contract supports the interface.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC1155, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // ** - VIEW - ** //
    /**
     * @notice Get the Elemxnt struct for a given ID.
     * @param id The ID of the Elemxnt to return.
     * @return Elemxnt The Elemxnt struct.
     */
    function getElemxnt(uint256 id) public view returns (Elemxnt memory) {
        return ELEMXNTS[id];
    }

    /**
     * @notice Check if a given address has already minted
     * @param _address The address to check
     * @return bool If the address has already minted
     */
    function hasMinted(address _address) public view returns (bool) {
        return minted.get(uint160(_address));
    }

    /**
     * @notice Get the owner of the contract.
     * @return address The owner of the contract.
     */
    function owner()
        public
        view
        override(Ownable, UpdatableOperatorFilterer)
        returns (address)
    {
        return Ownable.owner();
    }

    //** - ROYALTIES - ** //
    /**
     * @notice Update the default royalty fee the wallet that will receive it.
     * @param receiver The address of the wallet that will receive the royalty fee.
     * @param feeNumerator The basis points for the royalty.
     */
    function updateDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @notice Delete the default royalty fee.
     */
    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }
}