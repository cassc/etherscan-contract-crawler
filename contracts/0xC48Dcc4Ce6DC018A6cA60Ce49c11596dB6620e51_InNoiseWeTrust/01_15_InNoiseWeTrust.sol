// SPDX-License-Identifier: No License
// Copyright 404.zero, 2022

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract InNoiseWeTrust is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string public constant MANIFEST = (
        'ALL INFORMATION EXISTS IN THE CODE - NOTHING IS HIDDEN.\n'
        'ONCE THE CODE IS EXECUTED - WE ARE UNABLE TO CHANGE IT OR STOP IT.\n'
        'WE DO NOT HAVE FRIENDLY WHITELISTS - NOISE IS THE ONLY ACCESS TO INWT404.\n\n'

        'WE ONLY TALK TO THE NOISEFAMILY.\n'
        'ANYTHING THAT CAN BE SAID IS HIDDEN IN THE NOISE.\n'
        'EVERYTHING WE WILL SAY IS HIDDEN IN THE NOISE.\n'
        'DO NOT LOOK ELSEWHERE.\n\n'

        'NOISE WILL BE REBORN AS ENDLESSLY AS ALL OTHERS IN THIS WORLD.\n'
        'IN THE END, YOU CAN BRING NOTHING,\n'
        'BUT THE NOISE WILL ALWAYS FOLLOW YOU.\n'
        'DO NOT RESIST.\n\n'

        'WE FOLLOW A PARADIGM OF NOISE.\n'
        'WE DO NOT DEAL IN OTHER POLEMICS,\n'
        'WE TALK ONLY OF THE UNIFIED PERCEPTION OF THE WORLD,\n'
        'EXPRESSED THROUGH THE SINGLE MATERIAL AVAILABLE TO US,\n'
        'NOISE\n\n'

        'ANYTHING MORE THAN THAT IS AN ABUNDANCE OF LIARS.\n'
        'ANYTHING LESS THAN THAT IS HUMAN FEAR.\n\n'

        'DO NOT SEEK BEAUTY OUTSIDE.\n'
        'FIND THE NOISE INSIDE.\n\n'

        'AMEN\n\n'

        'IN NOISE WE TRUST'
    );

    struct NoiseDNA {
       bytes32 dna;
       uint256 programId;
       uint256 hinId;
       uint256 blockNumber;
    }

    struct NoiseShader {
        string sourceCode;
        string uniformTypes;
    }

    struct NoiseProgram {
        string sourceCode;
        uint256[] shaderIds;
    }

    address public constant HIN_ADDRESS = 0xf55dD62034b534e71Cb17EF6E2Bb112e93d6131A;
    uint256 public constant MINT_PRICE = 0.404 ether;
    uint256 public constant MINT_DURATION = 404;

    uint256 public lfgBlockNumber;

    mapping(uint256 => NoiseDNA) private _noiseDNA;
    mapping(uint256 => NoiseShader) private _noiseShaders;
    mapping(uint256 => NoiseProgram) private _noisePrograms;

    string public _noiseCore;

    mapping(uint256 => uint256) private _hinMints;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
    }

    modifier notLockedForever() {
        require((lfgBlockNumber + MINT_DURATION) > block.number || lfgBlockNumber == 0, "Contract is self-locked forever after the community drop");
        _;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function lfg(uint256 blockNumber) public onlyOwner notLockedForever {
        require(block.number <= blockNumber, "LFG should be greater than or equal to the current block");

        lfgBlockNumber = blockNumber;
    }

    function withdraw(uint256 amount) public payable onlyOwner {
        require(amount <= address(this).balance, "Insufficient funds to withdraw");

        payable(msg.sender).transfer(amount);
    }

    function mint(uint256[] calldata hinIds) public payable nonReentrant {
        require(block.number >= lfgBlockNumber && (lfgBlockNumber != 0), "Sale has not started yet");
        require(block.number < (lfgBlockNumber + MINT_DURATION), "Sale has already ended");

        require(hinIds.length > 0, "Mint at least 1 INWT at once");
        require(hinIds.length <= 10, "You can only mint 10 INWT at once");

        require(msg.value >= (MINT_PRICE * hinIds.length), "Insufficient funds to purchase");

        IERC721Enumerable hinContract = IERC721Enumerable(HIN_ADDRESS);

        for (uint256 i = 0; i < hinIds.length; i++) {
            uint256 hinId = hinIds[i];

            require(hinContract.ownerOf(hinId) == msg.sender, "You are not the owner of this HIN");
            require(_hinMints[hinId] == 0, "INWT with this HIN has already been minted");

            uint256 inwtId = totalSupply();

            _safeMint(msg.sender, inwtId);
            _synthesizeNoiseDNA(block.number, hinId, inwtId);

            _hinMints[hinId]++;
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");

        return string(
            abi.encodePacked(
                'data:application/json,'

                '{'
                    '"name":"', _noiseName(tokenId), '",'
                    '"description":"', _noiseDescription(tokenId), '",'
                    '"animation_url":"data:text/html;base64,', Base64.encode(_compileNoiseHTML(tokenId)), '",'
                    '"background_color":"000000"'
                '}'
            )
        );
    }

    function hinTokensCanMint(uint256[] calldata hinIds) public view returns (bool[] memory) {
        bool[] memory result = new bool[](hinIds.length);

        for (uint256 i = 0; i < hinIds.length; i++) {
            result[i] = _hinMints[hinIds[i]] == 0;
        }

        return result;
    }

    function hinTokenCanMint(uint256 hinId) public view returns (bool) {
        return _hinMints[hinId] == 0;
    }

    function noiseDNA(uint256 noiseId) public view virtual returns (NoiseDNA memory) {
        require(_exists(noiseId), "Noise does not exist");

        return _noiseDNA[noiseId];
    }

    function noiseHTML(uint256 noiseId) public view virtual returns (string memory) { // NOTE: Is it ok to return non base64-string? Noise holders should be available just copy-paste noises without any decoding.
        require(_exists(noiseId), "Noise does not exist");

        return string(_compileNoiseHTML(noiseId));
    }

    function setNoiseCore(string calldata core) public onlyOwner notLockedForever {
        _noiseCore = core;
    }

    function noiseCore() public view virtual returns (string memory) {
        return _noiseCore;
    }

    function setNoiseShader(uint256 shaderId, NoiseShader calldata shaderData) public onlyOwner notLockedForever {
        _noiseShaders[shaderId] = shaderData;
    }

    function noiseShader(uint256 shaderId) public view virtual returns (NoiseShader memory) {
        require(bytes(_noiseShaders[shaderId].sourceCode).length > 0, "Shader does not exist");

        return _noiseShaders[shaderId];
    }

    function setNoiseProgram(uint256 programId, NoiseProgram calldata programData) public onlyOwner notLockedForever {
        _noisePrograms[programId] = programData;
    }

    function noiseProgram(uint256 programId) public view virtual returns (NoiseProgram memory) {
        require(bytes(_noisePrograms[programId].sourceCode).length > 0, "Program does not exist");

        return _noisePrograms[programId];
    }

    function _synthesizeNoiseDNA(uint256 blockNumber, uint256 hinId, uint256 inwtId) private {
        _noiseDNA[inwtId] = NoiseDNA({
            dna: _mixNoiseDNA(blockNumber, hinId, inwtId),
            programId: _mixNoiseProgram(inwtId),
            hinId: hinId,
            blockNumber: blockNumber
        });
    }

    function _mixNoiseDNA(uint256 blockNumber, uint256 hinId, uint256 inwtId) private pure returns (bytes32) {
        return keccak256(abi.encode(blockNumber, hinId, inwtId));
    }

    function _mixNoiseProgram(uint256 inwtId) private pure returns (uint256) {
        return ((inwtId % 13) + ((inwtId * 2 + 19) % 17)) % 12;
    }

    function _noiseName(uint256 noiseId) private pure returns (bytes memory) {
        return abi.encodePacked('INWT ', (noiseId + 1).toString());
    }

    function _noiseDescription(uint256 noiseId) private view returns (bytes memory) {
        return abi.encodePacked('INNOISEWETRUST #', noiseId.toString(), '/', totalSupply().toString(), '. 404.zero, 2022');
    }

    function _compileNoiseHTML(uint256 noiseId) private view returns (bytes memory) {
        return abi.encodePacked(
            '<!DOCTYPE html>'
            '<html>'
                '<head>'
                    '<title>', _noiseName(noiseId), '</title>'
                    '<meta name="description" content="', _noiseDescription(noiseId), '" />'
                    '<style>body{background:#000;margin:0;padding:0;overflow:hidden;}</style>'
                '</head>'

                '<body>'
                    '<script type="application/javascript">', _noiseCore, _compileNoiseJS(noiseId), '</script>'
                '</body>'
            '</html>'

            '\n'
            '<!--'
            '\n', MANIFEST, '\n'
            '-->'
            '\n'
        );
    }

    function _compileNoiseJS(uint256 noiseId) private view returns (bytes memory) {
        NoiseProgram memory program = _noisePrograms[_noiseDNA[noiseId].programId];

        bytes memory shaders = '';

        for (uint256 i = 0; i < program.shaderIds.length; i++) {
            uint256 shaderId = program.shaderIds[i];

            shaders = abi.encodePacked(
                shaders, shaderId.toString(), ':["', _noiseShaders[shaderId].sourceCode, '","', _noiseShaders[shaderId].uniformTypes, '"],'
            );
        }

        return abi.encodePacked(
            'noise({', shaders, '},', program.sourceCode, ',"', Strings.toHexString(uint256(_noiseDNA[noiseId].dna), 32), '");'
        );
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}