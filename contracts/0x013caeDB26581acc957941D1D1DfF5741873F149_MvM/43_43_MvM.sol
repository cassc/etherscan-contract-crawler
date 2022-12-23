// SPDX-License-Identifier: Apache-2.0

/******************************************
 *  Amendeded by OBYC Labs Development    *
 *         Author: devAlex.eth            *
 ******************************************/

// Trademark S/N: 97720989
// Mutants v. Machines™
// OBYC Labs LLC
// www.givnerlawpc.com

pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/base/ERC721LazyMint.sol";
import "@thirdweb-dev/contracts/base/ERC1155Drop.sol";
import "@thirdweb-dev/contracts/eip/ERC721A.sol";
import "@thirdweb-dev/contracts/eip/ERC1155.sol";
import "@thirdweb-dev/contracts/extension/Ownable.sol";
import "@thirdweb-dev/contracts/lib/TWStrings.sol";

contract MvM is ERC721A, Ownable {
    using TWStrings for uint256;
    ERC721A public immutable obyc;

    ERC1155Drop public immutable obyclabs;
    bytes localBytes = new bytes(0);

    string public notRevealedUri;

    uint256[] public mvmL1Tokens; 
    uint256[] public mvmL2Tokens; 
    uint256[] public mvmL3Tokens; 

    uint256 public mvmL1TokensCount = 0; 
    uint256 public mvmL2TokensCount = 0; 
    uint256 public mvmL3TokensCount = 0; 

    string public baseURIL1 = "";
    string public baseURIL2 = "";
    string public baseURIL3 = "";

    bool public pauseMintL1 = false;
    bool public pauseMintL2 = true;
    bool public pauseMintL3 = true;

    struct TransformInfoLevelOne {
        address user;
        uint256 obycTokenId;
        uint256 obycLabsTokenId;
    }

    struct TransformInfoLevelTwo {
        address user;
        uint256 mvmLevelOneTokenId;
        uint256 obycTokenId;
        uint256 obycLabsTokenId;
    }

    struct TransformInfoLevelThree {
        address user;
        uint256 mvmLevelOneTokenId;
        uint256 mvmLevelTwoTokenId;
        uint256 obycTokenId;
        uint256 obycLabsTokenId;
    }

    mapping(uint256 => TransformInfoLevelOne)
        public transformInfoLevelOneByTokenId;

    mapping(uint256 => TransformInfoLevelTwo)
        public transformInfoLevelTwoByTokenId;

    mapping(uint256 => TransformInfoLevelThree)
        public transformInfoLevelThreeByTokenId;

    mapping(uint256 => uint256) public tokenIdStatus;

    constructor(
        string memory _name,
        string memory _symbol,
        address _obycAddress,
        address _obyclabsAddress
    ) ERC721A(_name, _symbol) {
        _setupOwner(msg.sender);
        obyc = ERC721A(_obycAddress);
        obyclabs = ERC1155Drop(_obyclabsAddress);
    }

    function isL1(uint256 _tokenId) public view returns (bool) {
        for (uint256 index = 0; index < mvmL1Tokens.length; index++) {
            if (mvmL1Tokens[index] == _tokenId) {
                return true;
            }
        }
        return false;
    }

    function isL2(uint256 _tokenId) public view returns (bool) {
        for (uint256 index = 0; index < mvmL2Tokens.length; index++) {
            if (mvmL2Tokens[index] == _tokenId) {
                return true;
            }
        }
        return false;
    }

    function isL3(uint256 _tokenId) public view returns (bool) {
        for (uint256 index = 0; index < mvmL3Tokens.length; index++) {
            if (mvmL3Tokens[index] == _tokenId) {
                return true;
            }
        }
        return false;
    }

    function isAlreadyMintedMvML1(uint256 _obycTokenId)
        public
        view
        returns (bool)
    {
        for (uint256 index = 0; index < mvmL1Tokens.length; index++) {
            if (
                transformInfoLevelOneByTokenId[mvmL1Tokens[index]]
                    .obycTokenId == _obycTokenId
            ) {
                return true;
            }
        }
        return false;
    }

    function isAlreadyMintedMvML2(uint256 _mvmTokenId)
        internal
        view
        returns (bool)
    {
        for (uint256 index = 0; index < mvmL2Tokens.length; index++) {
            if (
                transformInfoLevelTwoByTokenId[mvmL2Tokens[index]]
                    .mvmLevelOneTokenId == _mvmTokenId
            ) {
                return true;
            }
        }
        return false;
    }

    function isAlreadyMintedMvML3(uint256 _mvmTokenId)
        internal
        view
        returns (bool)
    {
        for (uint256 index = 0; index < mvmL3Tokens.length; index++) {
            if (
                transformInfoLevelThreeByTokenId[mvmL3Tokens[index]]
                    .mvmLevelTwoTokenId == _mvmTokenId
            ) {
                return true;
            }
        }
        return false;
    }

    function getStatusOfObycToken(uint256 _obycTokenId)
        public
        view
        returns (uint256[2] memory)
    {
        uint256 level = tokenIdStatus[_obycTokenId];
        uint256 tokenId=100001;
        if (level == 1) {
            for (uint256 index = 0; index < mvmL1Tokens.length; index++) {
                if (
                    transformInfoLevelOneByTokenId[mvmL1Tokens[index]]
                        .obycTokenId == _obycTokenId
                ) {
                    tokenId = mvmL1Tokens[index];
                }
            }
        } else if (level == 2) {
            for (uint256 index = 0; index < mvmL2Tokens.length; index++) {
                if (
                    transformInfoLevelTwoByTokenId[mvmL2Tokens[index]]
                        .obycTokenId == _obycTokenId
                ) {
                    tokenId = mvmL2Tokens[index];
                }
            }
        }
        else if (level == 3) {
            for (uint256 index = 0; index < mvmL3Tokens.length; index++) {
                if (
                    transformInfoLevelThreeByTokenId[mvmL3Tokens[index]]
                        .obycTokenId == _obycTokenId
                ) {
                    tokenId = mvmL3Tokens[index];
                }
            }
        }
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return [level, tokenId];
    }

    function isCorrectLabTokenForL2Mint(
        uint256 _obycLabTokenId,
        uint256 _mvmTokenId
    ) internal view returns (bool) {
        if (
            transformInfoLevelOneByTokenId[_mvmTokenId].obycLabsTokenId == 0 &&
            _obycLabTokenId == 2
        ) {
            return true;
        } else if (
            transformInfoLevelOneByTokenId[_mvmTokenId].obycLabsTokenId == 1 &&
            _obycLabTokenId == 3
        ) {
            return true;
        }
        return false;
    }

    function verifyClaim(
        uint256 _obycTokenId,
        uint256 _obycLabTokenId,
        uint256 _mvmL1TokenId,
        uint256 _mvmL2TokenId,
        uint256 _level
    ) public payable {
        if (_level == 1) {
            require(!pauseMintL1, "Minting for L1 is Paused");
            address tokenIdAdd = obyc.ownerOf(_obycTokenId);
            address sender = address(msg.sender);
            require(sender == tokenIdAdd, "You Dont Own the OBYC NFT");
            require(
                !isAlreadyMintedMvML1(_obycTokenId),
                "You Have Already Transformed this OBYC Token"
            );
            require(
                _obycLabTokenId == 0 || _obycLabTokenId == 1,
                "Wrong Lab Token Id for Level One Transformation"
            );
            require(
                obyc.balanceOf(msg.sender) >= 1,
                "You don't own enough OBYC NFTs"
            );
            // - They own an NFT from the OBYC Labs contract
            require(
                obyclabs.balanceOf(msg.sender, _obycLabTokenId) >= 1,
                "You don't own enough Level One Lab Items"
            );
            TransformInfoLevelOne
                memory transformInfoLevelOne = TransformInfoLevelOne(
                    msg.sender,
                    _obycTokenId,
                    _obycLabTokenId
                );
            transformInfoLevelOneByTokenId[
                _currentIndex
            ] = transformInfoLevelOne;
            mvmL1Tokens.push(_currentIndex);
            mvmL1TokensCount++;
            tokenIdStatus[_obycTokenId] = 1;
        } else if (_level == 2) {
            require(!pauseMintL2, "Minting for L2 is Paused");
            address tokenIdAdd = ownerOf(_mvmL1TokenId);
            address sender = address(msg.sender);
            require(sender == tokenIdAdd, "You Dont Own the MvM NFT");
            require(
                !isAlreadyMintedMvML2(_mvmL1TokenId),
                "You Have Already Transformed this MvM"
            );
            require(
                _obycLabTokenId == 2 || _obycLabTokenId == 3,
                "Wrong Lab Token Id for Level 2 Transformation"
            );
            require(
                balanceOf(msg.sender) >= 1,
                "You don't own enough OBYC Level Two NFTs"
            );
            // - They own an NFT from the OBYC Labs contract
            require(
                obyclabs.balanceOf(msg.sender, _obycLabTokenId) >= 1,
                "You don't own enough Level Two Lab Items"
            );
            require(
                isCorrectLabTokenForL2Mint(_obycLabTokenId, _mvmL1TokenId),
                "You Selected the Wrong Lab Token ID"
            );

            TransformInfoLevelTwo
                memory transformInfoLevelTwo = TransformInfoLevelTwo(
                    msg.sender,
                    _mvmL1TokenId,
                    transformInfoLevelOneByTokenId[_mvmL1TokenId].obycTokenId,
                    _obycLabTokenId
                );
            transformInfoLevelTwoByTokenId[
                _currentIndex
            ] = transformInfoLevelTwo;
            mvmL2Tokens.push(_currentIndex);
            mvmL2TokensCount++;
            tokenIdStatus[
                transformInfoLevelOneByTokenId[_mvmL1TokenId].obycTokenId
            ] = 2;
        }
         else if (_level == 3) {
            require(!pauseMintL3, "Minting for L3 is Paused");
            address tokenIdAdd = ownerOf(_mvmL2TokenId);
            address sender = address(msg.sender);
            require(sender == tokenIdAdd, "You Dont Own the MvM L2 NFT");
            require(
                !isAlreadyMintedMvML3(_mvmL2TokenId),
                "You Have Already Transformed this MvM"
            );
            require(
                _obycLabTokenId == 4,
                "Wrong Lab Token Id for Level 3 Transformation"
            );
            require(
                balanceOf(msg.sender) >= 1,
                "You don't own enough OBYC Level Two NFTs"
            );
            // - They own an NFT from the OBYC Labs contract
            require(
                obyclabs.balanceOf(msg.sender, _obycLabTokenId) >= 1,
                "You don't own enough Level Two Lab Items"
            );

            TransformInfoLevelThree
                memory transformInfoLevelThree = TransformInfoLevelThree(
                    msg.sender,
                    transformInfoLevelTwoByTokenId[_mvmL2TokenId].mvmLevelOneTokenId,
                    _mvmL2TokenId,
                    transformInfoLevelTwoByTokenId[_mvmL2TokenId].obycTokenId,
                    _obycLabTokenId
                );
            transformInfoLevelThreeByTokenId[
                _currentIndex
            ] = transformInfoLevelThree;
            mvmL3Tokens.push(_currentIndex);
            mvmL3TokensCount++;
            tokenIdStatus[
                transformInfoLevelTwoByTokenId[_mvmL2TokenId].obycTokenId
            ] = 3;
        }
    }

    //main mint function
    function mint(
        uint256 _obycTokenId,
        uint256 _obycLabTokenId,
        uint256 _mvmTokenId,
        uint256 _mvmL2TokenId,
        uint256 _level
    ) public payable {
        verifyClaim(_obycTokenId, _obycLabTokenId, _mvmTokenId,_mvmL2TokenId,_level);
        _safeMint(msg.sender, 1);
        //burning obyc lab token
        obyclabs.safeTransferFrom(
            address(msg.sender),
            address(0xdEaD00647e5Af4d45760F9442025e41a357E6990),
            _obycLabTokenId,
            1,
            localBytes
        );
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        // string memory batchUri = getBaseURI(_tokenId);
        // return string(abi.encodePacked(batchUri, _tokenId.toString()));
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (isL1(_tokenId)) {
            string memory currentBaseURI = _baseURI();
            return
                bytes(currentBaseURI).length > 0
                    ? string(
                        abi.encodePacked(
                            currentBaseURI,
                            _tokenId.toString(),
                            ".json"
                        )
                    )
                    : "";
        } else if (isL2(_tokenId)) {
            string memory currentBaseURI = _baseURILevelTwo();
            return
                bytes(currentBaseURI).length > 0
                    ? string(
                        abi.encodePacked(
                            currentBaseURI,
                            _tokenId.toString(),
                            ".json"
                        )
                    )
                    : "";
        } else if (isL2(_tokenId)) {
            string memory currentBaseURI = _baseURILevelThree();
            return
                bytes(currentBaseURI).length > 0
                    ? string(
                        abi.encodePacked(
                            currentBaseURI,
                            _tokenId.toString(),
                            ".json"
                        )
                    )
                    : "";
        }
        else {
            return "";
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURIL1;
    }
    // Set base URI of metadata (an IPFS URL) =======================
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURIL1 = _newBaseURI;
    }

    function _baseURILevelTwo() internal view virtual returns (string memory) {
        return baseURIL2;
    }
    // Set base URI of metadata (an IPFS URL) =======================
    function setBaseURILevelTwo(string memory _newBaseURILevelTwo) public onlyOwner {
        baseURIL2 = _newBaseURILevelTwo;
    }

    function _baseURILevelThree() internal view virtual returns (string memory) {
        return baseURIL3;
    }
    // Set base URI of metadata (an IPFS URL) =======================
    function setBaseURILevelThree(string memory _newBaseURILevelThree) public onlyOwner {
        baseURIL3 = _newBaseURILevelThree;
    }

    //setter function to pause/start level one mint
    function setPauseMintL1(bool _pauseMintL1) public onlyOwner {
        pauseMintL1 = _pauseMintL1;
    }

    //setter function to pause/start level two mint
    function setPauseMintL2(bool _pauseMintL2) public onlyOwner {
        pauseMintL2 = _pauseMintL2;
    }

    //setter function to pause/start level three mint
    function setPauseMintL3(bool _pauseMintL3) public onlyOwner {
        pauseMintL3 = _pauseMintL3;
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }
}