// SPDX-License-Identifier: MIT


// MANTICORE MUSK
// DSD X FVCKRENDER
// 👃🏼💎👃🏼💎👃🏼💎👃🏼💎👃🏼💎
/**


                                  .#@@@@@@@@@@@@@@@@@@@@@@@@@@&(.
                            (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&,
                       %@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
                 *  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.
            @   ,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
           *@  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%     %@
             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    %
                @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                  ,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                    ,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.    .#
                     [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@  [email protected]@@          *@@,
        %@@@@@@@@@@@@@@@@@@@@@@@@@@@@, #@&    [email protected]@*     &      %  (@@
       (/@@@@@@@@@@@@@@@@@@@@@@@@@%                ,             [email protected]@
       #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&           %@@@
      /@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    *@@@@,
      *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,
       ,&%  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.
            *@@@@@@@@@@@@@@@@@@@@@@@@@@@@//@@@@@@@@@@@@@@#
              @@@@@@@@@@@@@@@@@%           @@@@@@(   @@@@@@
                @@@@@@@@&&*@@@@@            @@@@@       @@@@@
              &@@@#         @@@@             @@@@         [email protected]@@,
             @@@@            @@@             @@@@           @@@
          @@@@@           (@@@@,        @@@@@@/           %@@@@.

                                                                      */
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./extensions/ERC721AQueryable.sol";
import "./ERC721A.sol";

error AllowlistRequired();
error ExceedsMintSize();
error ExceedsMaxPerTransaction();
error ExceedsMaxPerWallet();
error IncorrectPaymentAmount();
error InvalidMintSize();
error MintNotEnabled();
error PremintNotEnabled();
error NotAllowlisted();
error NotEnoughAllowlistSlots();
error NonExistentToken();

contract ManticoreMusk is Ownable, ERC721A, ReentrancyGuard, ERC721AQueryable {

    string private baseURI;

    uint public MAX_SUPPLY;
    uint public price = 0.11 ether;

    uint public maxPerTX     = 11;
    uint public maxPerWallet = 111;

    bool public mintEnabled = false;
    bool public preMintEnabled = false;

    bytes32 public freeMintRoot;
    bytes32 public preMintRoot;
    bytes32 public preMintBonusRoot;

    constructor(
        uint maxSupply_
    )
        ERC721A("ManticoreMusk", "MM")
    {
        MAX_SUPPLY = maxSupply_;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function preMint(bytes32[] calldata proof, bytes32[] calldata bonusProof, bytes32[] calldata freeProof, uint64 amount)
        external
        payable
        callerIsUser
        nonReentrant
    {
        if (!preMintEnabled) revert PremintNotEnabled();
        if (totalSupply() + amount > MAX_SUPPLY) revert ExceedsMintSize();

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        if (!MerkleProof.verify(
                proof,
                preMintRoot,
                leaf)
            ) revert NotAllowlisted();

        uint maxAllowlistMints = MerkleProof.verify(
                bonusProof,
                preMintBonusRoot,
                leaf) ? 2 : 1;

        uint cost = MerkleProof.verify(
                freeProof,
                freeMintRoot,
                leaf) ? 0 : price;

        if (msg.value != cost * amount) revert IncorrectPaymentAmount();

        uint64 numAllowlistMinted = _getAux(_msgSender()) + amount;
        if (numAllowlistMinted > maxAllowlistMints)
            revert NotEnoughAllowlistSlots();

        _mint(_msgSender(), amount);
        _setAux(_msgSender(), numAllowlistMinted);
    }

    function mint(uint256 amount)
      external
      payable
      callerIsUser
      nonReentrant {
        if (!mintEnabled) revert MintNotEnabled();
        if (msg.value != price * amount) revert IncorrectPaymentAmount();
        if (amount > maxPerTX) revert ExceedsMaxPerTransaction();
        if (amount > maxPerWallet) revert ExceedsMaxPerWallet();
        if (totalSupply() + amount >= MAX_SUPPLY) revert ExceedsMintSize();

        _mint(_msgSender(), amount);
    }

    function reserve(uint256 quantity, address to) external onlyOwner {
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "would exceed max supply"
        );
        _mint(to, quantity);
    }

    function setMaxPerTX(uint256 maxPerTX_) external onlyOwner {
        maxPerTX = maxPerTX_;
    }

    function setMaxPerWallet(uint256 maxPerWallet_) external onlyOwner {
        maxPerWallet = maxPerWallet_;
    }

    function setMaxSupply(uint256 maxSupply_) public onlyOwner {
        MAX_SUPPLY = maxSupply_;
    }

    function setFreeMintRoot(bytes32 freeMintRoot_) external onlyOwner{
        freeMintRoot = freeMintRoot_;
    }

    function setPreMintRoot(bytes32 preMintRoot_) external onlyOwner{
        preMintRoot = preMintRoot_;
    }

    function setPreMintBonusRoot(bytes32 preMintBonusRoot_) external onlyOwner {
        preMintBonusRoot = preMintBonusRoot_;
    }

    function getAux(address owner) public view returns (uint64) {
        return _getAux(owner);
    }

    function setAux(address owner, uint64 aux) external onlyOwner {
        _setAux(owner, aux);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function togglePremint() external onlyOwner {
        preMintEnabled = !preMintEnabled;
    }

    function toggleMint() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}