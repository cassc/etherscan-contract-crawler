// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./core/ChainRunnersTypes.sol";
import "./interfaces/IChainRunnersRenderer.sol";
import "./interfaces/IChainRunners.sol";
import "./ChainRunnersBaseRenderer.sol";

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

contract ChainRunnersXRBaseRenderer is Ownable, ReentrancyGuard {
    /**
     * @dev Emitted when the body type for `tokenId` token is changed to `to`.
     */
    event SetBodyType(address indexed owner, uint8 indexed to, uint256 indexed tokenId);

    uint256 public constant NUM_LAYERS = 13;
    uint256 public constant NUM_COLORS = 8;

    address public genesisRendererContractAddress;
    address public xrContractAddress;
    string public baseImageURI;
    string public baseAnimationURI;
    string public baseModelURI;
    string public modelStandardName;
    string public modelExtensionName;
    string public modelFileType;

    uint16[][NUM_LAYERS][3] WEIGHTS;

    struct BodyTypeOverride {
        bool isSet;
        uint8 id;
    }

    mapping(uint256 => BodyTypeOverride) bodyTypeOverrides;

    constructor(
        address genesisRendererContractAddress_
    ) {
        genesisRendererContractAddress = genesisRendererContractAddress_;

        /*
        This indexes into a race, then a layer index, then an array capturing the frequency each layer should be selected.
        Shout out to Anonymice for the rarity impl inspiration.
        */

        // Default
        WEIGHTS[0][0] = [36, 225, 225, 225, 360, 135, 27, 360, 315, 315, 315, 315, 225, 180, 225, 180, 360, 180, 45, 360, 360, 360, 27, 36, 360, 45, 180, 360, 225, 360, 225, 225, 360, 180, 45, 360, 18, 225, 225, 225, 225, 180, 225, 361];
        WEIGHTS[0][1] = [875, 1269, 779, 779, 779, 779, 779, 779, 779, 779, 779, 779, 17, 8, 41];
        WEIGHTS[0][2] = [172, 172, 172, 172, 86, 17, 0, 0, 86, 86, 86, 86, 17, 172, 86, 17, 172, 172, 172, 172, 172, 172, 17, 86, 172, 172, 172, 172, 172, 172, 172, 172, 6062];
        WEIGHTS[0][3] = [645, 0, 1290, 322, 645, 645, 645, 967, 322, 967, 645, 967, 967, 973];
        WEIGHTS[0][4] = [0, 0, 0, 1250, 1250, 1250, 1250, 1250, 1250, 1250, 1250];
        WEIGHTS[0][5] = [121, 121, 121, 121, 121, 121, 243, 0, 0, 0, 0, 121, 121, 243, 121, 121, 243, 121, 121, 121, 121, 121, 243, 121, 121, 121, 121, 243, 121, 121, 121, 121, 243, 121, 121, 121, 243, 121, 121, 121, 121, 243, 121, 121, 121, 121, 243, 121, 121, 121, 121, 243, 121, 121, 121, 121, 243, 121, 121, 121, 121, 243, 121, 121, 243, 0, 0, 0, 121, 121, 243, 121, 121, 306];
        WEIGHTS[0][6] = [833, 555, 138, 416, 694, 416, 138, 1111, 1111, 1111, 3477];
        WEIGHTS[0][7] = [88, 88, 88, 88, 88, 265, 442, 8853];
        WEIGHTS[0][8] = [189, 189, 47, 18, 9, 28, 37, 9483];
        WEIGHTS[0][9] = [340, 340, 340, 340, 340, 340, 34, 340, 340, 340, 340, 170, 170, 170, 102, 238, 238, 238, 272, 340, 340, 340, 272, 238, 238, 238, 238, 170, 34, 340, 340, 136, 340, 340, 340, 340, 344];
        WEIGHTS[0][10] = [159, 212, 106, 53, 26, 159, 53, 265, 53, 212, 159, 265, 53, 265, 265, 212, 53, 159, 239, 53, 106, 5, 106, 53, 212, 212, 106, 159, 212, 265, 212, 265, 5066];
        WEIGHTS[0][11] = [139, 278, 278, 250, 250, 194, 222, 278, 278, 194, 222, 83, 222, 278, 139, 139, 27, 278, 278, 278, 278, 27, 278, 139, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 27, 139, 139, 139, 139, 0, 278, 194, 83, 83, 278, 83, 27, 306];
        WEIGHTS[0][12] = [548, 1097, 182, 11, 274, 91, 365, 114, 7318];

        // Skull
        WEIGHTS[1][0] = [36, 225, 225, 225, 360, 135, 27, 360, 315, 315, 315, 315, 225, 180, 225, 180, 360, 180, 45, 360, 360, 360, 27, 36, 360, 45, 180, 360, 225, 360, 225, 225, 360, 180, 45, 360, 18, 225, 225, 225, 225, 180, 225, 361];
        WEIGHTS[1][1] = [875, 1269, 779, 779, 779, 779, 779, 779, 779, 779, 779, 779, 17, 8, 41];
        WEIGHTS[1][2] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10000];
        WEIGHTS[1][3] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        WEIGHTS[1][4] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        WEIGHTS[1][5] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 384, 7692, 1923, 0, 0, 0, 0, 0, 1];
        WEIGHTS[1][6] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10000];
        WEIGHTS[1][7] = [0, 0, 0, 0, 0, 909, 0, 9091];
        WEIGHTS[1][8] = [0, 0, 0, 0, 0, 0, 0, 10000];
        WEIGHTS[1][9] = [526, 526, 526, 0, 0, 0, 0, 0, 526, 0, 0, 0, 526, 0, 526, 0, 0, 0, 526, 526, 526, 526, 526, 526, 526, 526, 526, 526, 526, 0, 0, 526, 0, 0, 0, 0, 532];
        WEIGHTS[1][10] = [80, 0, 400, 240, 80, 0, 240, 0, 0, 80, 80, 80, 0, 0, 0, 0, 80, 80, 0, 0, 80, 80, 0, 80, 80, 80, 80, 80, 0, 0, 0, 0, 8000];
        WEIGHTS[1][11] = [289, 0, 0, 0, 0, 404, 462, 578, 578, 0, 462, 173, 462, 578, 0, 0, 57, 0, 57, 0, 57, 57, 578, 289, 578, 57, 0, 57, 57, 57, 578, 578, 0, 0, 0, 0, 0, 0, 57, 289, 578, 0, 0, 0, 231, 57, 0, 0, 1745];
        WEIGHTS[1][12] = [666, 666, 666, 0, 666, 0, 0, 0, 7336];

        // Bot
        WEIGHTS[2][0] = [36, 225, 225, 225, 360, 135, 27, 360, 315, 315, 315, 315, 225, 180, 225, 180, 360, 180, 45, 360, 360, 360, 27, 36, 360, 45, 180, 360, 225, 360, 225, 225, 360, 180, 45, 360, 18, 225, 225, 225, 225, 180, 225, 361];
        WEIGHTS[2][1] = [875, 1269, 779, 779, 779, 779, 779, 779, 779, 779, 779, 779, 17, 8, 41];
        WEIGHTS[2][2] = [172, 172, 172, 172, 86, 17, 0, 0, 86, 86, 86, 86, 17, 172, 86, 17, 172, 172, 172, 172, 172, 172, 17, 86, 172, 172, 172, 172, 172, 172, 172, 172, 6062];
        WEIGHTS[2][3] = [645, 0, 1290, 322, 645, 645, 645, 967, 322, 967, 645, 967, 967, 973];
        WEIGHTS[2][4] = [2500, 2500, 2500, 0, 0, 0, 0, 0, 0, 2500, 0];
        WEIGHTS[2][5] = [0, 0, 0, 0, 0, 0, 588, 588, 588, 588, 588, 0, 0, 588, 0, 0, 588, 0, 0, 0, 0, 0, 588, 0, 0, 0, 0, 588, 0, 0, 0, 588, 588, 0, 0, 0, 588, 0, 0, 0, 0, 588, 0, 0, 0, 0, 0, 0, 0, 0, 0, 588, 0, 0, 0, 0, 588, 0, 0, 0, 0, 588, 0, 0, 0, 0, 0, 0, 0, 0, 588, 0, 0, 4];
        WEIGHTS[2][6] = [833, 555, 138, 416, 694, 416, 138, 1111, 1111, 1111, 3477];
        WEIGHTS[2][7] = [88, 88, 88, 88, 88, 265, 442, 8853];
        WEIGHTS[2][8] = [183, 274, 274, 18, 18, 27, 36, 9170];
        WEIGHTS[2][9] = [340, 340, 340, 340, 340, 340, 34, 340, 340, 340, 340, 170, 170, 170, 102, 238, 238, 238, 272, 340, 340, 340, 272, 238, 238, 238, 238, 170, 34, 340, 340, 136, 340, 340, 340, 340, 344];
        WEIGHTS[2][10] = [217, 362, 217, 144, 72, 289, 144, 362, 72, 289, 217, 362, 72, 362, 362, 289, 0, 217, 0, 72, 144, 7, 217, 72, 217, 217, 289, 217, 289, 362, 217, 362, 3269];
        WEIGHTS[2][11] = [139, 278, 278, 250, 250, 194, 222, 278, 278, 194, 222, 83, 222, 278, 139, 139, 27, 278, 278, 278, 278, 27, 278, 139, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 27, 139, 139, 139, 139, 0, 278, 194, 83, 83, 278, 83, 27, 306];
        WEIGHTS[2][12] = [548, 1097, 182, 11, 274, 91, 365, 114, 7318];
    }

    /*
    Get race index.  Race index represents the "type" of base character:

    0 - Default, representing human and alien characters
    1 - Skull
    2 - Bot

    This allows skull/bot characters to have distinct trait distributions.
    */
    function getRaceIndex(uint16 _dna) public view returns (uint8) {
        uint16 lowerBound;
        uint16 percentage;
        for (uint8 i; i < WEIGHTS[0][1].length; i++) {
            percentage = WEIGHTS[0][1][i];
            if (_dna >= lowerBound && _dna < lowerBound + percentage) {
                if (i == 1) {
                    // Bot
                    return 2;
                } else if (i > 11) {
                    // Skull
                    return 1;
                } else {
                    // Default
                    return 0;
                }
            }
            lowerBound += percentage;
        }
        revert();
    }

    function getLayerIndex(uint16 _dna, uint8 _index, uint16 _raceIndex) public view returns (uint) {
        uint16 lowerBound;
        uint16 percentage;
        for (uint8 i; i < WEIGHTS[_raceIndex][_index].length; i++) {
            percentage = WEIGHTS[_raceIndex][_index][i];
            if (_dna >= lowerBound && _dna < lowerBound + percentage) {
                return i;
            }
            lowerBound += percentage;
        }
        // If not found, return index higher than available layers.  Will get filtered out.
        return WEIGHTS[_raceIndex][_index].length;
    }

    function _baseImageURI() internal view virtual returns (string memory) {
        return baseImageURI;
    }

    function setBaseImageURI(string calldata _baseImageURI) external onlyOwner {
        baseImageURI = _baseImageURI;
    }

    function _baseAnimationURI() internal view virtual returns (string memory) {
        return baseAnimationURI;
    }

    function setBaseAnimationURI(string calldata _baseAnimationURI) external onlyOwner {
        baseAnimationURI = _baseAnimationURI;
    }

    function _baseModelURI() internal view virtual returns (string memory) {
        return baseModelURI;
    }

    function setBaseModelURI(string calldata _baseModelURI) external onlyOwner {
        baseModelURI = _baseModelURI;
    }

    function _modelStandardName() internal view virtual returns (string memory) {
        return bytes(modelStandardName).length > 0 ? modelStandardName : 'EIP-XXXX';
    }

    function setModelStandardName(string calldata _modelStandardName) external onlyOwner {
        modelStandardName = _modelStandardName;
    }

    function _modelExtensionName() internal view virtual returns (string memory) {
        return bytes(modelExtensionName).length > 0 ? modelExtensionName : 'NIMDE-1';
    }

    function setModelExtensionName(string calldata _modelExtensionName) external onlyOwner {
        modelExtensionName = _modelExtensionName;
    }

    function _modelFileType() internal view virtual returns (string memory) {
        return bytes(modelFileType).length > 0 ? modelFileType : 'model/fbx';
    }

    function setModelFileType(string calldata _modelFileType) external onlyOwner {
        modelFileType = _modelFileType;
    }

    function _xrContractAddress() public view returns (address) {
        return xrContractAddress;
    }

    function setXRContractAddress(address _xrContractAddress) external onlyOwner {
        xrContractAddress = _xrContractAddress;
    }

    function setBodyTypeOverride(uint256 _tokenId, uint8 _bodyTypeId) external {
        IERC721 xrContract = IERC721(_xrContractAddress());
        require(xrContract.ownerOf(_tokenId) == msg.sender, "not the owner of token");

        bodyTypeOverrides[_tokenId] = BodyTypeOverride(true, _bodyTypeId % 2);

        emit SetBodyType(msg.sender, bodyTypeOverrides[_tokenId].id, _tokenId);
    }

    /*
    Generate base64 encoded tokenURI.

    All string constants are pre-base64 encoded to save gas.
    Input strings are padded with spacing/etc to ensure their length is a multiple of 3.
    This way the resulting base64 encoded string is a multiple of 4 and will not include any '=' padding characters,
    which allows these base64 string snippets to be concatenated with other snippets.
    */
    function tokenURI(uint256 _tokenId, ChainRunnersTypes.ChainRunner memory _runnerData) public view returns (string memory) {
        if (_tokenId <= 10000) {
            return genesisXRTokenURI(_tokenId, _runnerData.dna);
        }
        (ChainRunnersBaseRenderer.Layer [NUM_LAYERS] memory tokenLayers, ChainRunnersBaseRenderer.Color [NUM_COLORS][NUM_LAYERS] memory tokenPalettes, uint8 numTokenLayers, string[NUM_LAYERS] memory traitTypes) = getXRTokenData(_runnerData.dna);
        return base64TokenMetadata(_tokenId, tokenLayers, numTokenLayers, traitTypes, _runnerData.dna);
    }

    function genesisXRTokenURI(uint256 _tokenId, uint256 _dna) public view returns (string memory) {
        ChainRunnersBaseRenderer genesisRendererContract = ChainRunnersBaseRenderer(genesisRendererContractAddress);
        (ChainRunnersBaseRenderer.Layer [NUM_LAYERS] memory tokenLayers, ChainRunnersBaseRenderer.Color [NUM_COLORS][NUM_LAYERS] memory tokenPalettes, uint8 numTokenLayers, string[NUM_LAYERS] memory traitTypes) = genesisRendererContract.getTokenData(_dna);
        return base64TokenMetadata(_tokenId, tokenLayers, numTokenLayers, traitTypes, _dna);
    }

    function base64TokenMetadata(uint256 _tokenId,
        ChainRunnersBaseRenderer.Layer [NUM_LAYERS] memory _tokenLayers,
        uint8 _numTokenLayers,
        string[NUM_LAYERS] memory _traitTypes,
        uint256 _dna) public view returns (string memory) {

        string memory attributes;
        for (uint8 i = 0; i < _numTokenLayers; i++) {
            attributes = string(abi.encodePacked(attributes,
                bytes(attributes).length == 0 ? 'eyAg' : 'LCB7',
                'InRyYWl0X3R5cGUiOiAi', _traitTypes[i], 'IiwidmFsdWUiOiAi', _tokenLayers[i].name, 'IiB9'
                ));
        }
        string memory baseFileName = getBaseFileName(_tokenId, _dna);
        return string(abi.encodePacked(
                'data:application/json;base64,eyAiaW1hZ2UiOiAi',
                getBase64ImageURI(baseFileName),
                getBase64AnimationURI(baseFileName),
                'IiwgImF0dHJpYnV0ZXMiOiBb',
                attributes,
                'XSwgICAibmFtZSI6IlJ1bm5lciAj',
                getBase64TokenString(_tokenId),
                getBase64ModelMetadata(baseFileName),
                'LCAiZGVzY3JpcHRpb24iOiAiQ2hhaW4gUnVubmVycyBYUiBhcmUgM0QgTWVnYSBDaXR5IHJlbmVnYWRlcy4gIn0g'
            ));
    }

    function getBaseFileName(uint256 _tokenId, uint256 _dna) public view returns (string memory) {
        uint8 bodyTypeId = getBodyType(_tokenId, _dna);
        return string(abi.encodePacked(Strings.toString(_dna), '_', Strings.toString(bodyTypeId)));
    }

    function getBodyType(uint256 _tokenId, uint256 _dna) public view returns (uint8) {
        BodyTypeOverride memory bodyTypeOverride = bodyTypeOverrides[_tokenId];
        if (bodyTypeOverride.isSet) {
            return bodyTypeOverride.id;
        }
        return uint8((_dna & (uint256(1111111) << (14 * NUM_LAYERS))) >> (14 * NUM_LAYERS)) % 2;
    }

    function getBase64TokenString(uint256 _tokenId) public view returns (string memory) {
        return Base64.encode(uintToByteString(_tokenId, 6));
    }

    function getBase64ImageURI(string memory _baseFileName) public view returns (string memory) {
        return Base64.encode(padStringBytes(abi.encodePacked(_baseImageURI(), _baseFileName), 3));
    }

    function getBase64AnimationURI(string memory _baseFileName) public view returns (string memory) {
        return bytes(_baseAnimationURI()).length > 0
            ? string(abi.encodePacked('IiwgImFuaW1hdGlvbl91cmwiOiAi', Base64.encode(bytes(padString(string(abi.encodePacked(_baseImageURI(), _baseFileName)), 3)))))
            : '';
    }

    function getBase64ModelMetadata(string memory _baseFileName) public view returns (string memory) {
        return Base64.encode(padStringBytes(abi.encodePacked(
            '","metadataStandard": "',
            _modelStandardName(),
            '","extensions": [ "',
            _modelExtensionName(),
            '" ],"assets": [{ "mediaType": "model", "assetType": "avatar", "files": [{"url": "',
            _baseModelURI(),
                _baseFileName,
            '","fileType": "',
            _modelFileType(),
            '"}]}]'
        ), 3));
    }

    function getTokenData(uint256 _tokenId, uint256 _dna) public view returns (ChainRunnersBaseRenderer.Layer [NUM_LAYERS] memory tokenLayers, ChainRunnersBaseRenderer.Color [NUM_COLORS][NUM_LAYERS] memory tokenPalettes, uint8 numTokenLayers, string [NUM_LAYERS] memory traitTypes) {
        if (_tokenId <= 10000) {
            ChainRunnersBaseRenderer genesisRendererContract = ChainRunnersBaseRenderer(genesisRendererContractAddress);
            return genesisRendererContract.getTokenData(_dna);
        }
        return getXRTokenData(_dna);
    }

    function getXRTokenData(uint256 _dna) public view returns (ChainRunnersBaseRenderer.Layer [NUM_LAYERS] memory tokenLayers, ChainRunnersBaseRenderer.Color [NUM_COLORS][NUM_LAYERS] memory tokenPalettes, uint8 numTokenLayers, string [NUM_LAYERS] memory traitTypes) {
        uint16[NUM_LAYERS] memory dna = splitNumber(_dna);
        uint16 raceIndex = getRaceIndex(dna[1]);

        bool hasFaceAcc = dna[7] < (10000 - WEIGHTS[raceIndex][7][7]);
        bool hasMask = dna[8] < (10000 - WEIGHTS[raceIndex][8][7]);
        bool hasHeadBelow = dna[9] < (10000 - WEIGHTS[raceIndex][9][36]);
        bool hasHeadAbove = dna[11] < (10000 - WEIGHTS[raceIndex][11][48]);
        bool useHeadAbove = (dna[0] % 2) > 0;
        for (uint8 i = 0; i < NUM_LAYERS; i ++) {
            ChainRunnersBaseRenderer genesisRenderer = ChainRunnersBaseRenderer(genesisRendererContractAddress);
            ChainRunnersBaseRenderer.Layer memory layer = genesisRenderer.getLayer(i, uint8(getLayerIndex(dna[i], i, raceIndex)));
            if (layer.hexString.length > 0) {
                /*
                These conditions help make sure layer selection meshes well visually.
                1. If mask, no face/eye acc/mouth acc
                2. If face acc, no mask/mouth acc/face
                3. If both head above & head below, randomly choose one
                */
                if (((i == 2 || i == 12) && !hasMask && !hasFaceAcc) || (i == 7 && !hasMask) || (i == 10 && !hasMask) || (i < 2 || (i > 2 && i < 7) || i == 8 || i == 9 || i == 11)) {
                    if (hasHeadBelow && hasHeadAbove && (i == 9 && useHeadAbove) || (i == 11 && !useHeadAbove)) continue;
                    tokenLayers[numTokenLayers] = layer;
                    traitTypes[numTokenLayers] = ["QmFja2dyb3VuZCAg","UmFjZSAg","RmFjZSAg","TW91dGgg","Tm9zZSAg","RXllcyAg","RWFyIEFjY2Vzc29yeSAg","RmFjZSBBY2Nlc3Nvcnkg","TWFzayAg","SGVhZCBCZWxvdyAg","RXllIEFjY2Vzc29yeSAg","SGVhZCBBYm92ZSAg","TW91dGggQWNjZXNzb3J5"][i];
                    numTokenLayers++;
                }
            }
        }
        return (tokenLayers, tokenPalettes, numTokenLayers, traitTypes);
    }

    function splitNumber(uint256 _number) internal view returns (uint16[NUM_LAYERS] memory numbers) {
        for (uint256 i = 0; i < numbers.length; i++) {
            numbers[i] = uint16(_number % 10000);
            _number >>= 14;
        }
        return numbers;
    }

    /*
    Convert uint to byte string, padding number string with spaces at end.
    Useful to ensure result's length is a multiple of 3, and therefore base64 encoding won't
    result in '=' padding chars.
    */
    function uintToByteString(uint _a, uint _fixedLen) internal pure returns (bytes memory _uintAsString) {
        uint j = _a;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(_fixedLen);
        j = _fixedLen;
        if (_a == 0) {
            bstr[0] = "0";
            len = 1;
        }
        while (j > len) {
            j = j - 1;
            bstr[j] = bytes1(' ');
        }
        uint k = len;
        while (_a != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_a - _a / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _a /= 10;
        }
        return bstr;
    }

    function padString(string memory _s, uint256 _multiple) internal view returns (string memory) {
        uint256 numPaddingSpaces = (_multiple - (bytes(_s).length % _multiple)) % _multiple;
        while (numPaddingSpaces > 0) {
            _s = string(abi.encodePacked(_s, ' '));
            numPaddingSpaces--;
        }
        return _s;
    }

    function padStringBytes(bytes memory _s, uint256 _multiple) internal view returns (bytes memory) {
        uint256 numPaddingSpaces = (_multiple - (_s.length % _multiple)) % _multiple;
        while (numPaddingSpaces > 0) {
            _s = abi.encodePacked(_s, ' ');
            numPaddingSpaces--;
        }
        return _s;
    }
}