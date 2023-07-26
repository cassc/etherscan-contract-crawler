// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

//                               .:
//                               ^#J^
//                               ~&GJJ^
//                               5?JJ~YJ.
//                              ~G  !57!Y7
//                              P!   .?5775~         :^~!!77777?PJ!^:.
//                             ^G      :5G7YJ    .~7J?!~^^::::::^:~!7???7~:
//                             ?Y        [email protected]??5.:7Y7^.   ~:             .^!?J?:
//                             5?         [email protected]??B?^     ..!?.            .   .~JJ:
//                             JJ      ~: ^@#.G^:.   .^  .            .^   ^Y^~Y?.
//                             ^G.    .Y   B& YJ7Y.                 7:      ..  !G:
//                              ?5.   .P. .#P.5? .            ~.~~  ^Y!.         7P  .:^~!77??JJJJ7!^.
//                               75!. ~JJYB&5J#!                .~J!  !?7~^:~!7~.:5P??JYYY5555P5?YGPJ^
//                                [email protected]@~~5Y.  .^~~~!^.:^~^ .?~.~J!:..^^:^^!?~::YPBGYYJ?7!~~^7J:
//                                   .^GP557!:  :??~^^JPJJY?!!77^~?!:^~.^!.~77~:^[email protected]:.     .J7
//                                   .5#.       .:  .P#J7!!???!~J! ^J!!7!  .: ~!!!~!::P!     ~5~
//                                  :[email protected] ~?.   :.   .BB5YGBPYJJYJGJ ~BG5J~!!~ :7?!:^. P? .~7J?.
//                                 [email protected]&: ^~  !J7:    !BY!?PGG5JPB##GBBGG##!^!YB5J5G7^[email protected]?:
//                                [email protected]     JJ.       ^YPY?77JPP5J??JJYY5G#&@@@GYG#.?PJ7~:
//                              .YY 7#.    .G.          .^~7GP^        ..:^~7YGPJBG?G
//                             ~P7 :B~      P7            :Y!               .?:!#?.!JJ^
//                          .~YY: :P~       :J           ~5:    ..      :       ~5.  ^5?
//                    .^!7???7^  :BJ    !!^~^^75:      :7BJY?7777~    ^!P7.      7Y   .B.
//               .^!?J?7~:.      [email protected]   7Y7PG#BJ#! !!  5B5?!~^^:..     .:~J7       P: .J5
//          .:!7??7~:            :[email protected]  ?75Y#&~5&#BJB7.JBBGGBBBBGGGP5J~ .        ~ Y5GP!
//       ^!?J7~:.                  7#7 .:JY&B7G#&&:[email protected]:^P: .~!7?JJY5P5YGGPY7.   ~JY#7.
//   .~?J?~:                        :P7   :?YYPG#G ?&@B:^5^ !?YPG####BG577YPP?~. 5&!
// ^?J7^                             .5J    :YPG&#:~&&&5 .Y7    .?&@@@P^  ^5#@&#PP&!  .
// ?^                                  ?5^   .!Y#&5P####^..?5~  .JPBY77!^Y&@@#[email protected]!55.
//                                      ^57     :Y#5??P&P5BGJ?57. :!7!^7JPP5YJ5GBP?!YY.
//                                        ?5:     ^P5?:~?Y#B.^G7P5PG5Y5GBJ!J?G#GJ~7P!
//                                         ~P!     .JG5. .~?JGPG5#GBBBG55PJ77JBJ?!^!Y?:
//                                          .YJ.     ^!~     :^~~~::. .!?!..JG?.     ~Y?:
//                                            7P^      ::....        7!: .JGJ.         ~5?.
//                ~7.                          ^5?:...^77????J??77!^^^:!5GJ:             75~
//                .7Y7.                          ~77???7777777??JYYYPGP57.                :5J
//                   75!                                          .::.                      J5.
//                    .JY:                                                            .~     ?P.
//                      ~P!                                                            JY     JY
//                       .5J                                                            YY     P!
//                         YY                                                            5J    ^G^
//                          YY                                                            P7    ^57
//                           P?                                                           :G~     J5.

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Bofa is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    bytes32 public merkleRoot;
    mapping(address => bool) public whitelistClaimed;

    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;

    uint256 public cost;
    uint256 public maxSupply;
    uint256 public maxMintAmountPerTx;
    uint256 public maxMintAmountPerWallet = 1;

    bool public paused = true;
    bool public whitelistMintEnabled = false;
    bool public revealed = false;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _cost,
        uint256 _maxSupply,
        uint256 _maxMintAmountPerTx,
        string memory _hiddenMetadataUri
    ) ERC721A(_tokenName, _tokenSymbol) {
        setCost(_cost);
        maxSupply = _maxSupply;
        setMaxMintAmountPerTx(_maxMintAmountPerTx);
        setHiddenMetadataUri(_hiddenMetadataUri);
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");
        _;
    }

    function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        public
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount)
    {
        require(whitelistMintEnabled, "The whitelist sale is not enabled!");
        require(!whitelistClaimed[_msgSender()], "Address already claimed!");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof!"
        );

        whitelistClaimed[_msgSender()] = true;
        _safeMint(_msgSender(), _mintAmount);
    }

    function mint(uint256 _mintAmount)
        public
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount)
    {
        require(!paused, "The contract is paused!");
        require(
            balanceOf(msg.sender) <= maxMintAmountPerWallet,
            "Max mint for this address"
        );

        _safeMint(_msgSender(), _mintAmount);
    }

    function updateMaxPerWallet(uint256 _maxPerWallet) public onlyOwner {
        require(paused, "The contract is not paused!");
        maxMintAmountPerWallet = _maxPerWallet;
    }

    function mintForAddress(uint256 _mintAmount, address _receiver)
        public
        mintCompliance(_mintAmount)
        onlyOwner
    {
        _safeMint(_receiver, _mintAmount);
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = _startTokenId();
        uint256 ownedTokenIndex = 0;
        address latestOwnerAddress;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId < _currentIndex
        ) {
            TokenOwnership memory ownership = _ownerships[currentTokenId];

            if (!ownership.burned) {
                if (ownership.addr != address(0)) {
                    latestOwnerAddress = ownership.addr;
                }

                if (latestOwnerAddress == _owner) {
                    ownedTokenIds[ownedTokenIndex] = currentTokenId;

                    ownedTokenIndex++;
                }
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 0;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx)
        public
        onlyOwner
    {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setWhitelistMintEnabled(bool _state) public onlyOwner {
        whitelistMintEnabled = _state;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}