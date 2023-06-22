// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "../../core/OmmgArtistContract.sol";

//  .----------------.  .----------------.  .----------------.  .----------------.
// | .--------------. || .--------------. || .--------------. || .--------------. |
// | |     ____     | || | ____    ____ | || | ____    ____ | || |    ______    | |
// | |   .'    `.   | || ||_   \  /   _|| || ||_   \  /   _|| || |  .' ___  |   | |
// | |  /  .--.  \  | || |  |   \/   |  | || |  |   \/   |  | || | / .'   \_|   | |
// | |  | |    | |  | || |  | |\  /| |  | || |  | |\  /| |  | || | | |    ____  | |
// | |  \  `--'  /  | || | _| |_\/_| |_ | || | _| |_\/_| |_ | || | \ `.___]  _| | |
// | |   `.____.'   | || ||_____||_____|| || ||_____||_____|| || |  `._____.'   | |
// | |              | || |              | || |              | || |              | |
// | '--------------' || '--------------' || '--------------' || '--------------' |
//  '----------------'  '----------------'  '----------------'  '----------------'
//               _                   _____  _      _                  _____                      _
//      /\      | |                 |  __ \(_)    | |                / ____|                    (_)
//     /  \   __| | __ _ _ __ ___   | |__) |_  ___| |__   ___  ___  | |  __  ___ _ __   ___  ___ _ ___
//    / /\ \ / _` |/ _` | '_ ` _ \  |  _  /| |/ __| '_ \ / _ \/ __| | | |_ |/ _ \ '_ \ / _ \/ __| / __|
//   / ____ \ (_| | (_| | | | | | | | | \ \| | (__| | | |  __/\__ \ | |__| |  __/ | | |  __/\__ \ \__ \
//  /_/    \_\__,_|\__,_|_| |_| |_| |_|  \_\_|\___|_| |_|\___||___/  \_____|\___|_| |_|\___||___/_|___/

/// @title AdamRichesGenesis
/// @author NotAMeme aka nxlogixnick
/// @notice Adam Riches is an emerging British painter and draughtsman who primarily works in monochromatic color palette.
/// The characteristically stylized portraits and figurative works he creates are based on a sensitive response to the human condition,
/// ranging from furious expressive moments to poignant, melancholy reflections.
/// This is his NFT genesis collection. It contains excellent and rare pieces made in his famous drawing style.
/// Riches has taken part in numerous international exhibitions and artist residencies.
/// His works can be found in private collections around the world. Learn more at http://adamrichesartist.com/
contract AdamRichesGenesis is OmmgArtistContract {
    string public constant Artist = "Adam Riches";

    constructor(ArtistContractConfig memory config)
        OmmgArtistContract(config)
    {}
}