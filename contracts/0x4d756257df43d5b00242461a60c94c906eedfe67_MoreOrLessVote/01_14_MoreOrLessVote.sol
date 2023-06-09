// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./MoreOrLessArt.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                          //
//  .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  //
// | .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. | //
// | |     _  _     | || | ____    ____ | || |     ____     | || |  _______     | || |  _________   | || |     _  _     | | //
// | |    | || |    | || ||_   \  /   _|| || |   .'    `.   | || | |_   __ \    | || | |_   ___  |  | || |    | || |    | | //
// | |    \_|\_|    | || |  |   \/   |  | || |  /  .--.  \  | || |   | |__) |   | || |   | |_  \_|  | || |    \_|\_|    | | //
// | |              | || |  | |\  /| |  | || |  | |    | |  | || |   |  __ /    | || |   |  _|  _   | || |              | | //
// | |              | || | _| |_\/_| |_ | || |  \  `--'  /  | || |  _| |  \ \_  | || |  _| |___/ |  | || |              | | //
// | |              | || ||_____||_____|| || |   `.____.'   | || | |____| |___| | || | |_________|  | || |              | | //
// | |              | || |              | || |              | || |              | || |              | || |              | | //
// | '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' | //
//  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  //
//                                          .----------------.  .----------------.                                          //
//                                         | .--------------. || .--------------. |                                         //
//                                         | |     ____     | || |  _______     | |                                         //
//                                         | |   .'    `.   | || | |_   __ \    | |                                         //
//                                         | |  /  .--.  \  | || |   | |__) |   | |                                         //
//                                         | |  | |    | |  | || |   |  __ /    | |                                         //
//                                         | |  \  `--'  /  | || |  _| |  \ \_  | |                                         //
//                                         | |   `.____.'   | || | |____| |___| | |                                         //
//                                         | |              | || |              | |                                         //
//                                         | '--------------' || '--------------' |                                         //
//                                          '----------------'  '----------------'                                          //
//  .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  //
// | .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. | //
// | |     _  _     | || |   _____      | || |  _________   | || |    _______   | || |    _______   | || |     _  _     | | //
// | |    | || |    | || |  |_   _|     | || | |_   ___  |  | || |   /  ___  |  | || |   /  ___  |  | || |    | || |    | | //
// | |    \_|\_|    | || |    | |       | || |   | |_  \_|  | || |  |  (__ \_|  | || |  |  (__ \_|  | || |    \_|\_|    | | //
// | |              | || |    | |   _   | || |   |  _|  _   | || |   '.___`-.   | || |   '.___`-.   | || |              | | //
// | |              | || |   _| |__/ |  | || |  _| |___/ |  | || |  |`\____) |  | || |  |`\____) |  | || |              | | //
// | |              | || |  |________|  | || | |_________|  | || |  |_______.'  | || |  |_______.'  | || |              | | //
// | |              | || |              | || |              | || |              | || |              | || |              | | //
// | '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' | //
//  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  //
//                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
contract MoreOrLessVote is ERC721Enumerable, Ownable {

    using Strings for uint256;
    using Strings for uint16;
    using Strings for uint8;

    uint16 public moreVotes;
    uint16 public lessVotes;

    uint16 public constant maxSupply = 1000;

    struct Vote {       
        address votedBy;
        bool isTheDecider;
        bool influencer;
        uint16[2] votesAtTime;
        bool vote;
    }

    Vote[maxSupply + 1] public voteInfos;
    MoreOrLessArt.Art[maxSupply + 1] public artInfos;

    mapping(address => bool) private hasVoted;

    constructor() ERC721("More or Less", "MORL") {
        uint256 mintNum = 0;
        _safeMint(msg.sender, mintNum);
        hasVoted[msg.sender] = true;
        voteInfos[0].votedBy = msg.sender;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(
            'data:application/json;utf8,',
            '{"name":"More Or Less #',
                (tokenId).toString(),
            '",',
            '"description":"',
                getDescription(tokenId),
            '",',
            '"image":"',
                _generateImage(tokenId),
            '", "attributes":[',
                getMetadata(tokenId),
            ']',
        '}'));
    }

    function getDescription(uint256 tokenId) private pure returns (string memory) {
        if (tokenId == 0) {
            return "This is the genesis token for the MORE or LESS experiment by @yungwknd. It is constantly changing to reflect the unknown results of this experiment and all the possible different outputs.";
        }
        if (tokenId == maxSupply) {
            return "This is the closing token for the MORE or LESS experiment by @yungwknd. While its image may change, the metadata reflects the final sealing of the vote and what the participants decided.";
        }
        return "Provenance is everything. MORE or LESS is a social experiment by @yungwknd. It attempts to answer the question 'would you rather donate $100 or give me $10?'. Each participant receives a commemorative NFT as they vote to donate MORE or LESS. Thank you for participating.";
    }

    function _getVoteString(bool voteMore) private pure returns (string memory) {
        if (voteMore) {
            return "MORE";
        } else {
            return "LESS";
        }
    }

    function getSpecialMetadata(uint256 tokenId) private view returns (string memory) {
        if (tokenId == 0) {
            return string(abi.encodePacked(
                MoreOrLessArt._wrapTrait("Token Vote", "Abstain"),
                ',',MoreOrLessArt._wrapTrait("Created By", MoreOrLessArt.addressToString(voteInfos[tokenId].votedBy)),
                ',',MoreOrLessArt._wrapTrait("Genesis Token", "True"),
                ',',MoreOrLessArt._wrapTrait("Live Image", "True")
            ));
        } else if (tokenId == maxSupply) {
            return string(abi.encodePacked(
                MoreOrLessArt._wrapTrait("Token Vote", "Abstain"),
                ',',MoreOrLessArt._wrapTrait("Sealed By", MoreOrLessArt.addressToString(voteInfos[tokenId].votedBy)),
                ',',MoreOrLessArt._wrapTrait("Final Vote Count", string(abi.encodePacked(
                    moreVotes.toString(),
                    " MORE and ",
                    lessVotes.toString(),
                    " LESS."))),
                ',',MoreOrLessArt._wrapTrait("Live Image", "True")
            ));
        }
        return "";
    }

    function getMetadata(uint256 tokenId) public view returns (string memory) {
        if (tokenId == 0 || tokenId == maxSupply) {
            return getSpecialMetadata(tokenId);
        }
        string memory metadata = string(abi.encodePacked(
            MoreOrLessArt._wrapTrait("Token Vote", _getVoteString(voteInfos[tokenId].vote)),
            ',',MoreOrLessArt._wrapTrait("Voted By", MoreOrLessArt.addressToString(voteInfos[tokenId].votedBy)),
            ',',getVotesAtTime(tokenId)
        ));

        if (artInfos[tokenId].whichShape == 0) {
            metadata = string(abi.encodePacked(
            metadata,
            ',',
            MoreOrLessArt._wrapTrait("Circles", artInfos[tokenId].numCircles.toString())
            ));
        } else if (artInfos[tokenId].whichShape == 1) {
            metadata = string(abi.encodePacked(
            metadata,
            ',',
            MoreOrLessArt._wrapTrait("Rectangles", artInfos[tokenId].numRects.toString())
            ));
        } else if (artInfos[tokenId].whichShape == 2) {
            metadata = string(abi.encodePacked(
            metadata,
            ',',
            MoreOrLessArt._wrapTrait("Triangles", artInfos[tokenId].numTriangles.toString())
            ));
        } else {
            metadata = string(abi.encodePacked(
            metadata,
            ',',MoreOrLessArt._wrapTrait("Rectangles", artInfos[tokenId].numRects.toString()),
            ',',MoreOrLessArt._wrapTrait("Triangles", artInfos[tokenId].numTriangles.toString()),
            ',',MoreOrLessArt._wrapTrait("Circles", artInfos[tokenId].numCircles.toString())
            ));
        }

        metadata = string(abi.encodePacked(
            metadata,
            ',',
            MoreOrLessArt._wrapTrait("Lines", artInfos[tokenId].numLines.toString())
        ));

        if (voteInfos[tokenId].isTheDecider) {
            metadata = string(abi.encodePacked(
            metadata,
            ',',
            MoreOrLessArt._wrapTrait("Decider", "True")
            ));
        }
        if (voteInfos[tokenId].influencer) {
            metadata = string(abi.encodePacked(
                metadata,
                ',',
                MoreOrLessArt._wrapTrait("Influencer", "True")
            ));
        }
        
        return metadata;
    }

    function getVotesAtTime(uint256 tokenId) public view returns (string memory) {
        return string(abi.encodePacked(
            MoreOrLessArt._wrapTrait("Votes at Time", string(abi.encodePacked(
                voteInfos[tokenId].votesAtTime[0].toString(),
                " MORE and ",
                voteInfos[tokenId].votesAtTime[1].toString(),
                " LESS.")))
        ));
    }

    function mintMORE() public payable {
        require(hasVoted[msg.sender] == false, 'Cannot vote twice.');
        require(msg.value > 100000000, 'Not enough ETH');
        require(totalSupply() < maxSupply, 'No more voting');
        uint256 mintNum = totalSupply();
        _safeMint(msg.sender, mintNum);
        hasVoted[msg.sender] = true;
        uint256 num = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, "MORE")));
        artInfos[mintNum].randomTimestamp = uint48(block.timestamp);
        artInfos[mintNum].randomDifficulty = uint128(block.difficulty);
        artInfos[mintNum].randomSeed = num;
        voteInfos[mintNum].votedBy = msg.sender;
        voteInfos[mintNum].votesAtTime = [moreVotes, lessVotes];
        voteInfos[mintNum].vote = true;
        _saveImageInfo(artInfos[mintNum]);
        voteInfos[mintNum].influencer = moreVotes == lessVotes;
        moreVotes++;
        voteInfos[mintNum].isTheDecider = moreVotes == 10 && lessVotes < 10;
    }

    function mintLESS() public payable {
        require(hasVoted[msg.sender] == false, 'Cannot vote twice.');
        require(msg.value > 10000000, 'Not enough ETH');
        require(totalSupply() < maxSupply, 'No more voting');
        uint256 mintNum = totalSupply();
        _safeMint(msg.sender, mintNum);
        hasVoted[msg.sender] = true;
        uint256 num = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, "LESS")));
        artInfos[mintNum].randomTimestamp = uint48(block.timestamp);
        artInfos[mintNum].randomDifficulty = uint128(block.difficulty);
        artInfos[mintNum].randomSeed = num;
        voteInfos[mintNum].votedBy = msg.sender;
        voteInfos[mintNum].votesAtTime = [moreVotes, lessVotes];
        voteInfos[mintNum].vote = false;
        _saveImageInfo(artInfos[mintNum]);
        voteInfos[mintNum].influencer = moreVotes == lessVotes;
        lessVotes++;
        voteInfos[mintNum].isTheDecider = lessVotes == 10 && moreVotes < 10;
    }

    function _generateImage(uint256 mintNum) private view returns (string memory) {
        MoreOrLessArt.Art memory artData = artInfos[mintNum];
        if (mintNum == 0 || mintNum == maxSupply) {
            artData.randomTimestamp = uint48(block.timestamp);
            artData.randomDifficulty = uint128(block.difficulty);
            artData.randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, "MOREORLESS")));
            artData.whichShape = uint8(MoreOrLessArt.seededRandom(0, 4, artData.randomSeed, artData));
            artData.numRects = uint8(MoreOrLessArt.seededRandom(1,10, artData.randomSeed+1, artData));
            artData.numCircles = uint8(MoreOrLessArt.seededRandom(1,10, artData.randomSeed+2, artData));
            artData.numTriangles = uint8(MoreOrLessArt.seededRandom(1,10, artData.randomSeed+3, artData));
            artData.numLines = uint8(MoreOrLessArt.seededRandom(1,10,artData.randomSeed+4, artData));
        }
        string memory triangles = MoreOrLessArt._generateTriangles(artData);
        string memory circles = MoreOrLessArt._generateCircles(artData);
        string memory rectangles = MoreOrLessArt._generateRectangles(artData);
        string memory lines = MoreOrLessArt._generateLines(artData);

        if (artInfos[mintNum].whichShape == 0) {
            return string(abi.encodePacked(MoreOrLessArt._generateHeader(mintNum, artData), circles, lines, MoreOrLessArt._imageFooter));
        } else if (artInfos[mintNum].whichShape == 1) {
            return string(abi.encodePacked(MoreOrLessArt._generateHeader(mintNum, artData), rectangles, lines, MoreOrLessArt._imageFooter));
        } else if (artInfos[mintNum].whichShape == 2) {
            return string(abi.encodePacked(MoreOrLessArt._generateHeader(mintNum, artData), triangles, lines, MoreOrLessArt._imageFooter));
        }

        return string(abi.encodePacked(MoreOrLessArt._generateHeader(mintNum, artData), circles, triangles, rectangles, lines, MoreOrLessArt._imageFooter));
    }

    function _saveImageInfo(MoreOrLessArt.Art storage artInfo) private {
        uint256 seed = artInfo.randomSeed;
        artInfo.whichShape = uint8(MoreOrLessArt.seededRandom(0, 4, seed, artInfo));
        artInfo.numRects = uint8(MoreOrLessArt.seededRandom(1, 10, seed + 1, artInfo));
        artInfo.numCircles = uint8(MoreOrLessArt.seededRandom(1, 10, seed + 2, artInfo));
        artInfo.numTriangles = uint8(MoreOrLessArt.seededRandom(1, 10, seed + 3, artInfo));
        artInfo.numLines = uint8(MoreOrLessArt.seededRandom(1, 10, seed + 4, artInfo));
    }

    function withdraw(address _to, uint amount) public onlyOwner {
        payable(_to).transfer(amount);
    }

    function sealVote(address _to) public onlyOwner {
        require(totalSupply() == maxSupply, "Voting must be complete.");
        uint256 mintNum = maxSupply;
        _safeMint(_to, mintNum);
        voteInfos[maxSupply].votedBy = msg.sender;
    }

}