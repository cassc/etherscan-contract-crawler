// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "./libs/IDescriptor.sol";
import "./libs/StringsA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DescriptorBBC is IDescriptor, Ownable {
    using StringsA for uint256;

    address public descriptedContract;
    string private _baseURL =
        "https://arweave.net/DKpf6UOgobZQIua-Y3_t-VrWWf6TuJZX9ZR_CTASnIw11/";
    string private _baseURLVeil =
        "https://arweave.net/DKpf6UOgobZQIua-Y3_t-VrWWf6TuJZX9ZR_CTASnIw/";
    string private _imageExt = ".png";
    string private _imageExtVeil = ".jpg";
    string private constant _name = "BabyBunta 2nd collection";
    string private _description =
        unicode'\\"Bunta\\" is one of the most fashionable pugs and loves to make people happy.  \\n  He%27s a baby but he looks like an uncle!  \\n  \\n  I am striving to reach the top of the pug world someday.  \\n  \\n  \\"ぶんた\\"はパグの中でも大のオシャレ好きで、人を幸せにする事が大好きです。  \\n  赤ちゃんですが見た目はおじさんです！  \\n  \\n  いつの日かパグ界の頂点を目指して奮闘中です。';

    bool public revealed;

    error InvalidCaller(address caller);

    constructor(address __addr) {
        setDescriptedContract(__addr);
    }

    function setDescriptedContract(address _addr) public onlyOwner {
        descriptedContract = _addr;
    }

    function setBaseURL(string memory _newURL) external onlyOwner {
        _baseURL = _newURL;
    }

    function setBaseURLVeil(string memory _newURL) external onlyOwner {
        _baseURLVeil = _newURL;
    }

    function setImageExt(string memory _newExt) external onlyOwner {
        _imageExt = _newExt;
    }

    function setImageExtVeil(string memory _newExt) external onlyOwner {
        _imageExtVeil = _newExt;
    }

    function setDescription(string memory _newDescription) external onlyOwner {
        _description = _newDescription;
    }

    function setReveal(bool _state) external onlyOwner {
        revealed = _state;
    }

    function tokenURI(uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        if (msg.sender != descriptedContract) revert InvalidCaller(msg.sender);
        string memory strId = tokenId.toString();
        string memory imageId;
        string memory url;
        string memory extension;
        if (revealed) {
            imageId = strId;
            url = _baseURL;
            extension = _imageExt;
        } else {
            imageId = (uint256(keccak256(abi.encodePacked("BBC#", tokenId))) %
                3).toString();
            url = _baseURLVeil;
            extension = _imageExtVeil;
        }

        return
            string.concat(
                "data:application/json;,",
                '{"name":"',
                _name,
                " #",
                strId,
                '","description":"',
                _description,
                '","image":"',
                url,
                imageId,
                extension,
                '","attributes":{}}'
            );
    }
}