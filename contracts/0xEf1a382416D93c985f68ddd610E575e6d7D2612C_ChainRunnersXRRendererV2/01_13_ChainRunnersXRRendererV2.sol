// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./core/ChainRunnersTypes.sol";
import "./interfaces/IChainRunnersRenderer.sol";
import "./interfaces/IChainRunners.sol";
import "./ChainRunnersBaseRenderer.sol";
import "./ChainRunnersXRBaseRenderer.sol";

/*
               ::::                                                                                                                                                  :::#%=
               @*==+-                                                                                                                                               ++==*=.
               #+=#=++..                                                                                                                                        ..=*=*+-#:
                :=+++++++=====================================:    .===============================================. .=========================================++++++++=
                 .%-+%##+=--==================================+=..=+-=============================================-+*+======================================---+##+=#-.
                   [email protected]@%[email protected]@@%+++++++++++++++++++++++++++%#++++++%#+++#@@@#[email protected]@%[email protected]#+.=+*@*+*@@@@*+++++++++++++++++++++++%@@@#+++#@@+++=
                    -*-#%@@%%%=*%@%*++=++=+==+=++=++=+=++=++==#@%#%#+++=+=*@%*+=+==+=+++%*[email protected]%%#%#++++*@%#++=++=++=++=+=++=++=+=+*%%*==*%@@@*:%=
                     :@:[email protected]@@@@@*+++%@@*+===========+*=========#@@========+#%==========*@========##*#*+=======*@##*======#@#+=======*#*============+#%++#@@%#@@#++=.
                      .*+=%@%*%@%##[email protected]@%#=-==-=--==*%=========*%==--=--=-====--=--=-=##=--=-=--%%%%%+=-=--=-=*%=--=--=-=#%=--=----=#%=--=-=--=-+%#+==#%@@*#%@=++.
                        +%.#@@###%@@@@@%*---------#@%########@%*---------------------##---------------------##---------%%*[email protected]@#---------+#@=#@@#[email protected]@%*++-
                        .:*+*%@#+=*%@@@*=-------=#%#=-------=%*---------=*#*--------#+=--------===--------=#%*-------=#%*[email protected]%#--------=%@@%#*+=-+#%*+*:.
       ====================%*[email protected]@%#==+##%@*[email protected]#[email protected]@*-------=*@[email protected]@*[email protected][email protected]=--------*@@+-------+#@@%#==---+#@.*%====================
     :*=--==================-:=#@@%*===+*@%+=============%%%@=========*%@*[email protected]+=--=====+%@[email protected][email protected]========*%@@+======%%%**+=---=%@#=:-====================-#-
       +++**%@@@#*****************@#*=---=##%@@@@@@@@@@@@@#**@@@@****************%@@*[email protected]#***********#@************************************+=------=*@#*********************@#+=+:
        .-##=*@@%*----------------+%@%=---===+%@@@@@@@*+++---%#++----------------=*@@*+++=-----------=+#=------------------------------------------+%+--------------------+#@[email protected]
         :%:#%#####+=-=-*@@+--=-==-=*@=--=-==-=*@@#*[email protected][email protected]%===-==----+-==-==--+*+-==-==---=*@@@@@@%#===-=-=+%@%-==-=-==-#@%=-==-==--+#@@@@@@@@@@@@*+++
        =*=#@#=----==-=-=++=--=-==-=*@=--=-==-=*@@[email protected]===-=--=-*@@*[email protected]=--=-==--+#@-==-==---+%-==-==---=+++#@@@#--==-=-=++++-=--=-===#%[email protected]@@%.#*
        +#:@%*===================++%#=========%@%=========#%=========+#@%+=======#%==========*@#=========*%=========+*+%@@@+========+*[email protected]@%+**+================*%#*=+=
       *++#@*+=++++++*#%*+++++=+++*%%++++=++++%%*=+++++++##*=++++=++=%@@++++=++=+#%++++=++++#%@=+++++++=*#*+++++++=#%@@@@@*++=++++=#%@*[email protected]#*****=+++++++=+++++*%@@+:=+=
    :=*=#%#@@@@#%@@@%#@@#++++++++++%%*+++++++++++++++++**@*+++++++++*%#++++++++=*##++++++++*%@%+++++++++##+++++++++#%%%%%%++++**#@@@@@**+++++++++++++++++=*%@@@%#@@@@#%@@@%#@++*:.
    #*:@#=-+%#+:=*@*[email protected]%#++++++++#%@@#*++++++++++++++#%@#*++++++++*@@#[email protected]#++++++++*@@#+++++++++##*+++++++++++++++++###@@@@++*@@#+++++++++++++++++++*@@#=:+#%[email protected]*=-+%*[email protected]=
    ++=#%#+%@@%=#%@%#+%%#++++++*#@@@%###**************@@@++++++++**#@##*********#*********#@@#++++++***@#******%@%#*++**#@@@%##+==+++=*#**********%%*++++++++#%#=%@@%+*%@%*+%#*=*-
     .-*+===========*@@+++++*%%%@@@++***************+.%%*++++#%%%@@%=:=******************[email protected]@#+++*%%@#==+***--*@%*++*%@@*===+**=--   -************[email protected]%%#++++++#@@@*==========*+-
        =*******##.#%#++++*%@@@%+==+=             *#-%@%**%%###*====**-               [email protected]:*@@##@###*==+**-.-#[email protected]@#*@##*==+***=                     =+=##%@*+++++*%@@#.#%******:
               ++++%#+++*#@@@@+++==.              **[email protected]@@%+++++++===-                 -+++#@@+++++++==:  :+++%@@+++++++==:                          [email protected]%##[email protected]@%++++
             :%:*%%****%@@%+==*-                .%==*====**+...                      #*.#+==***....    #+=#%+==****:.                                ..-*=*%@%#++*#%@=+%.
            -+++#%+#%@@@#++===                  [email protected]*++===-                            #%++===           %#+++===                                          =+++%@%##**@@*[email protected]:
          .%-=%@##@@%*==++                                                                                                                                 .*==+#@@%*%@%=*=.
         .+++#@@@@@*++==.                                                                                                                                    -==++#@@@@@@=+%
       .=*=%@@%%%#=*=.                                                                                                                                          .*+=%@@@@%+-#.
       @[email protected]@@%:++++.                                                                                                                                              -+++**@@#+*=:
    .-+=*#%%++*::.                                                                                                                                                  :+**=#%@#==#
    #*:@*+++=:                                                                                                                                                          [email protected]*++=:
  :*-=*=++..                                                                                                                                                             .=*=#*.%=
 +#.=+++:                                                                                                                                                                   ++++:+#
*+=#-::                                                                                                                                                                      .::*+=*

*/

contract ChainRunnersXRRendererV2 is Ownable {
    uint256 public constant NUM_LAYERS = 13;
    uint256 public constant NUM_COLORS = 8;

    address internal _genesisRendererContractAddress;
    address internal _xrBaseRendererContractAddress;
    string internal _baseImageURI;
    string internal _baseAnimationURI;
    string internal _baseModelURI;
    string internal _modelStandardName;
    string internal _modelExtensionName;
    mapping(uint => string) internal _modelFileTypes;
    uint internal _numModelFileTypes;

    constructor(
        address genesisRendererContractAddress,
        address xrBaseRendererContractAddress,
        string memory baseImageURI,
        string memory baseAnimationURI,
        string memory baseModelURI,
        string[] memory modelFileTypes
    ) {
        _genesisRendererContractAddress = genesisRendererContractAddress;
        _xrBaseRendererContractAddress = xrBaseRendererContractAddress;
        _baseImageURI = baseImageURI;
        _baseAnimationURI = baseAnimationURI;
        _baseModelURI = baseModelURI;
        setModelFileTypes(modelFileTypes);
    }

    function baseImageURI() public view returns (string memory) {
        return _baseImageURI;
    }

    function setBaseImageURI(string calldata baseImageURI) external onlyOwner {
        _baseImageURI = baseImageURI;
    }

    function baseAnimationURI() public view returns (string memory) {
        return _baseAnimationURI;
    }

    function setBaseAnimationURI(string calldata baseAnimationURI) external onlyOwner {
        _baseAnimationURI = baseAnimationURI;
    }

    function baseModelURI() public view returns (string memory) {
        return _baseModelURI;
    }

    function setBaseModelURI(string calldata baseModelURI) external onlyOwner {
        _baseModelURI = baseModelURI;
    }

    function modelStandardName() public view returns (string memory) {
        return bytes(_modelStandardName).length > 0 ? _modelStandardName : 'ETM_v1.0.0';
    }

    function setModelStandardName(string calldata modelStandardName) external onlyOwner {
        _modelStandardName = modelStandardName;
    }

    function modelExtensionName() public view returns (string memory) {
        return bytes(_modelExtensionName).length > 0 ? _modelExtensionName : 'ETM_MULTIASSET_v1.0.0';
    }

    function setModelExtensionName(string calldata modelExtensionName) external onlyOwner {
        _modelExtensionName = modelExtensionName;
    }

    function modelFileTypes() public view returns (string[] memory) {
        string[] memory result;
        for (uint i = 0; i < _numModelFileTypes; i++) {
            result[i] = _modelFileTypes[i];
        }
        return result;
    }

    function setModelFileTypes(string[] memory modelFileTypes) public onlyOwner {
        _numModelFileTypes = modelFileTypes.length;
        for (uint i = 0; i < _numModelFileTypes; i++) {
            _modelFileTypes[i] = modelFileTypes[i];
        }
    }

    function xrBaseRendererContractAddress() public view returns (address) {
        return _xrBaseRendererContractAddress;
    }

    function setXRBaseRendererContractAddress(address xrBaseRendererContractAddress) external onlyOwner {
        _xrBaseRendererContractAddress = xrBaseRendererContractAddress;
    }

    /*
    Generate base64 encoded tokenURI.

    All string constants are pre-base64 encoded to save gas.
    Input strings are padded with spacing/etc to ensure their length is a multiple of 3.
    This way the resulting base64 encoded string is a multiple of 4 and will not include any '=' padding characters,
    which allows these base64 string snippets to be concatenated with other snippets.
    */
    function tokenURI(uint256 tokenId, ChainRunnersTypes.ChainRunner memory runnerData) public view returns (string memory) {
        if (tokenId <= 10000) {
            return genesisXRTokenURI(tokenId, runnerData.dna);
        }
        return xrTokenURI(tokenId, runnerData.dna);
    }

    function genesisXRTokenURI(uint256 tokenId, uint256 dna) public view returns (string memory) {
        ChainRunnersBaseRenderer genesisRendererContract = ChainRunnersBaseRenderer(_genesisRendererContractAddress);
        (ChainRunnersBaseRenderer.Layer [NUM_LAYERS] memory tokenLayers, ChainRunnersBaseRenderer.Color [NUM_COLORS][NUM_LAYERS] memory tokenPalettes, uint8 numTokenLayers, string[NUM_LAYERS] memory traitTypes) = genesisRendererContract.getTokenData(dna);
        return base64TokenMetadata(tokenId, tokenLayers, numTokenLayers, traitTypes, dna);
    }

    function xrTokenURI(uint256 tokenId, uint256 dna) public view returns (string memory) {
        ChainRunnersXRBaseRenderer xrBaseRendererContract = ChainRunnersXRBaseRenderer(_xrBaseRendererContractAddress);
        (ChainRunnersBaseRenderer.Layer [NUM_LAYERS] memory tokenLayers, ChainRunnersBaseRenderer.Color [NUM_COLORS][NUM_LAYERS] memory tokenPalettes, uint8 numTokenLayers, string[NUM_LAYERS] memory traitTypes) = xrBaseRendererContract.getXRTokenData(dna);
        return base64TokenMetadata(tokenId, tokenLayers, numTokenLayers, traitTypes, dna);
    }

    function base64TokenMetadata(uint256 tokenId,
        ChainRunnersBaseRenderer.Layer [NUM_LAYERS] memory tokenLayers,
        uint8 numTokenLayers,
        string[NUM_LAYERS] memory traitTypes,
        uint256 dna) public view returns (string memory) {

        string memory attributes;
        for (uint8 i = 0; i < numTokenLayers; i++) {
            attributes = string(abi.encodePacked(attributes,
                bytes(attributes).length == 0 ? 'eyAg' : 'LCB7',
                'InRyYWl0X3R5cGUiOiAi', traitTypes[i], 'IiwidmFsdWUiOiAi', tokenLayers[i].name, 'IiB9'
                ));
        }
        string memory baseFileName = getBaseFileName(tokenId, dna);
        return string(abi.encodePacked(
                'data:application/json;base64,eyAiaW1hZ2UiOiAi',
                getBase64ImageURI(baseFileName),
                getBase64AnimationURI(baseFileName),
                'IiwgImF0dHJpYnV0ZXMiOiBb',
                attributes,
                'XSwgICAibmFtZSI6IlJ1bm5lciAj',
                getBase64TokenString(tokenId),
                getBase64ModelMetadata(baseFileName),
                'LCAiZGVzY3JpcHRpb24iOiAiQ2hhaW4gUnVubmVycyBYUiBhcmUgM0QgTWVnYSBDaXR5IHJlbmVnYWRlcy4gIn0g'
            ));
    }

    function getBaseFileName(uint256 tokenId, uint256 dna) public view returns (string memory) {
        ChainRunnersXRBaseRenderer xrBaseRendererContract = ChainRunnersXRBaseRenderer(_xrBaseRendererContractAddress);
        uint8 bodyTypeId = xrBaseRendererContract.getBodyType(tokenId, dna);
        return string(abi.encodePacked(Strings.toString(dna), '_', Strings.toString(bodyTypeId)));
    }

    function getBase64TokenString(uint256 tokenId) public view returns (string memory) {
        return Base64.encode(uintToByteString(tokenId, 6));
    }

    function getBase64ImageURI(string memory baseFileName) public view returns (string memory) {
        return Base64.encode(padStringBytes(abi.encodePacked(baseImageURI(), baseFileName), 3));
    }

    function getBase64AnimationURI(string memory baseFileName) public view returns (string memory) {
        return bytes(baseAnimationURI()).length > 0
            ? string(abi.encodePacked(
                'IiwgImFuaW1hdGlvbl91cmwiOiAi',
                Base64.encode(bytes(padString(string(abi.encodePacked(baseAnimationURI(), baseFileName)), 3)))))
            : '';
    }

    function getBase64ModelMetadata(string memory baseFileName) public view returns (string memory) {
        return Base64.encode(padStringBytes(abi.encodePacked(
            '","metadata_standard": "',
            modelStandardName(),
            '","extensions": [ "',
            modelExtensionName(),
            '" ],"assets": [{ "media_type": "model", "asset_type": "avatar", "files":',
            getModelFilesArray(baseFileName),
            '}]'
        ), 3));
    }

    function getModelFilesArray(string memory baseFileName) public view returns (string memory) {
        string memory result = '[';
        for (uint i = 0; i < _numModelFileTypes; i++) {
            result = string(abi.encodePacked(
                result,
                '{"url": "',
                baseModelURI(),
                    baseFileName,
                '.',
                _modelFileTypes[i],
                '","file_type":"model/',
                _modelFileTypes[i],
                '"}',
                i != _numModelFileTypes -1 ? ',' : ''
            ));
        }
        return string(abi.encodePacked(result, ']'));
    }

    function getTokenData(uint256 tokenId, uint256 dna) public view returns (ChainRunnersBaseRenderer.Layer [NUM_LAYERS] memory tokenLayers, ChainRunnersBaseRenderer.Color [NUM_COLORS][NUM_LAYERS] memory tokenPalettes, uint8 numTokenLayers, string [NUM_LAYERS] memory traitTypes) {
        if (tokenId <= 10000) {
            ChainRunnersBaseRenderer genesisRendererContract = ChainRunnersBaseRenderer(_genesisRendererContractAddress);
            return genesisRendererContract.getTokenData(dna);
        }
        ChainRunnersXRBaseRenderer xrBaseRendererContract = ChainRunnersXRBaseRenderer(_xrBaseRendererContractAddress);
        return xrBaseRendererContract.getXRTokenData(dna);
    }

    /*
    Convert uint to byte string, padding number string with spaces at end.
    Useful to ensure result's length is a multiple of 3, and therefore base64 encoding won't
    result in '=' padding chars.
    */
    function uintToByteString(uint i, uint fixedLen) internal pure returns (bytes memory uintAsString) {
        uint j = i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(fixedLen);
        j = fixedLen;
        if (i == 0) {
            bstr[0] = "0";
            len = 1;
        }
        while (j > len) {
            j = j - 1;
            bstr[j] = bytes1(' ');
        }
        uint k = len;
        while (i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(i - i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            i /= 10;
        }
        return bstr;
    }

    function padString(string memory s, uint256 multiple) internal view returns (string memory) {
        uint256 numPaddingSpaces = (multiple - (bytes(s).length % multiple)) % multiple;
        while (numPaddingSpaces > 0) {
            s = string(abi.encodePacked(s, ' '));
            numPaddingSpaces--;
        }
        return s;
    }

    function padStringBytes(bytes memory s, uint256 multiple) internal view returns (bytes memory) {
        uint256 numPaddingSpaces = (multiple - (s.length % multiple)) % multiple;
        while (numPaddingSpaces > 0) {
            s = abi.encodePacked(s, ' ');
            numPaddingSpaces--;
        }
        return s;
    }
}