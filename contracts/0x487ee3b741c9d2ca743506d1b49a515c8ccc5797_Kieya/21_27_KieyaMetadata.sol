// SPDX-License-Identifier: GPL-3.0
// presented by Wildxyz

pragma solidity ^0.8.17;

import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {Base64} from '@openzeppelin/contracts/utils/Base64.sol';

contract KieyaMetadata {

    string[200] private KieyaElement = ["Multi","Sun","Water","Thunder","Wind","Sun","Water","Thunder","Wind","Sun","Water","Thunder","Wind","Sun","Water","Thunder","Wind","Sun","Water","Wind","Thunder","Sun","Water","Thunder","Wind","Sun","Water","Thunder","Wind","Sun","Water","Thunder","Wind","Sun","Water","Thunder","Wind","Sun","Water","Thunder","Wind","Sun","Water","Thunder","Wind","Sun","Wind","Sun","Water","Thunder","Sun","Thunder","Water","Thunder","Wind","Sun","Water","Thunder","Wind","Sun","Water","Thunder","Wind","Sun","Water","Thunder","Wind","Sun","Water","Thunder","Wind","Sun","Water","Thunder","Sun","Water","Thunder","Wind","Sun","Water","Thunder","Wind","Sun","Water","Thunder","Wind","Sun","Water","Thunder","Wind","Sun","Water","Thunder","Wind","Sun","Water","Thunder","Wind","Sun","Water","Thunder","Wind","Sun","Water","Thunder","Wind","Sun","Multi","Thunder","Wind","Sun","Water","Thunder","Wind","Sun","Water","Thunder","Wind","Sun","Water","Thunder","Wind","Sun","Water","Thunder","Wind","Sun","Water","Thunder","Wind","Sun","Water","Thunder","Wind","Sun","Water","Thunder","Wind","Sun","Water","Thunder","Wind","Sun","Water","Thunder","Wind","Sun","Water","Sun","Multi","Wind","Sun","Water","Thunder","Wind","Sun","Water","Thunder","Wind","Sun","Water","Thunder","Wind","Sun","Multi","Thunder","Wind","Sun","Water","Thunder","Wind","Sun","Water","Thunder","Multi","Sun","Water","Thunder","Wind","Sun","Water","Thunder","Wind","Sun","Water","Thunder","Wind","Multi","Sun","Water","Thunder","Wind","Sun","Water","Thunder","Sun","Water","Thunder","Multi","Multi"];
    uint16[200] private KieyaType = [4,1,1,3,1,2,3,3,2,2,1,3,2,3,3,2,2,1,1,1,2,1,1,2,1,3,2,2,1,2,2,2,2,3,2,2,2,1,3,2,3,3,1,2,1,3,2,2,3,2,3,3,3,3,2,1,2,3,2,3,3,3,3,3,2,2,2,3,3,2,3,3,3,3,3,2,1,3,3,1,2,3,2,3,3,3,3,3,2,3,3,1,1,2,1,2,2,3,3,3,2,3,3,1,3,3,3,4,3,2,3,3,3,2,3,3,2,3,3,1,2,1,3,3,3,3,3,2,2,3,2,2,2,1,3,2,1,3,3,3,2,1,3,1,3,3,2,2,3,4,3,2,2,3,3,2,3,3,1,2,3,3,3,2,4,3,2,3,2,2,2,2,1,3,4,3,3,2,3,2,3,2,1,2,2,2,3,4,2,1,2,1,1,1,2,2,1,1,4,4];
    string[200] private KieyaName = ["Mistweaver","Flameheart","Shadowcaster","Spellbinder","Nightshade","Starcaller","Frostweaver","Moonwhisper","Soulshaper","Emberfrost","Stormbreaker","Dreamweaver","Shadowthorn","Frostfire","Shadowstrike","Moonshaper","Frostwind","Spellbound","Shadowfire","Starwhisper","Nightengale","Mindbender","Frostbloom","Illusionist","Etherwalker","Mirageborn","Realityshaper","Enigmaheart","Psychebloom","Shadowseer","Celestialweaver","Luminary","Eternalfire","Dawnbringer","Aquafrost","Radiance","Daydreamer","Sunweaver","Wavebreaker","Lightcaster","Goldenheart","Brightwing","Galaxius","Stardust","Starborn","Cosmosphere","Lunaris","Novaflare","Celestine","Nebulastorm","Galaxyfire","Cosmospark","Luminary","Starshine","Everglow","Moonbeam","Stardancer","Stellaris","Wildheart","Starstrike","Dreamwoven"," Thunderstorm","Radiantwing","Soulrender"," Empyreal"," Arcaneheart"," Voidweaver","Moonfire","Eternalight","Mistweaver","Shadowcaster","Novaflare","Spellbinder","Stormrider","Nightshade","Frostweaver","Starcaller","Moonwhisper","Soulshaper","Emberfrost","Stormbreaker","Dreamweaver","Shadowthorn","Frostfire","Stormweaver","Shadowstrike","Emberheart","Moonshaper","Spellbound","Starwhisper","Shadowfire","Starwhisper","Nightengale","Stormborn","Moonshadow","Frostbloom","Starweaver","Moonstone","Flamecaster","Spellbinder","Shadowheart","Stormrider","Flamestrike","Frostglade","Dreamweaver","Mindbender","Realityshaper","Enigmaheart","Psychebloom","Shadowseer","Celestialweaver","Luminary","Soulweaver","Reverieflux","Eternalfire","Aquafrost","Radiance","Daydreamer","Sunweaver","Wavebreaker"," Lightcaster","Daystar","Sunshadow","Goldenheart","Starweaver","Nebulight","Starseeker","Celestia","Galaxius","Stardust","Novaflare","Starwhisper","Nebulashade","Galaxywind","Lunaris","Celestine","Nebulastorm","Starborne","Galaxyfire","Luminary","Cosmospark","Starshine","Everglow","Moonbeam","Starlight","Astralwind","Starflare","Stellaris"," Luminara","Cosmosurge","Wildheart","Flameheart","Alexandros","Stormrider","Everglow","Starstrike","Dreamwoven","Soulrender","Radiantwing","Moonfire","Arcaneheart","Empyreal","Luminary","Novaflare","Mistweaver","Eternalight","Spellbinder","Starcaller","Moonwhisper","Soulshaper","Stormbreaker","Dreamweaver","Frostfire","Stormweaver","Nightengale","Shadowstrike","Moonshaper","Starwhisper","Stormborn","Flamecaster","Frostfall","Starweaver","Moonstone","Nightfire","Moonwhisper","Shadowdancer","Dreamweaver","Mindbender","Illusionist","Realityshaper","Enigmaheart","Spiritwhisper","Psychebloom","Celestialweaver","Veilstorm","Luminary","Wavebreaker","Stormrider","Daydreamer","Galaxius"];
    string[200] private KieyaAura = ["Gentle","Calm","Tranquil","Passion","Mystery","Bright","Darkness","Dynamic","Playful","Harmony","Balance","Majestic","Euphoric","Serene","Divine","Heavenly","Radiant","Wrath","Darkness","Serene","Peaceful","Darkness","Euphoric","Majestic","Balance","Harmony","Playful","Dynamic","Vibrant","Darkness","Bright","Mystery","Passion ","Calm","Tranquil","Gentle","Dynamic","Darkness","Vibrant","Wrath","Radiant","Harmony","Divine ","Heavenly","Ethereal ","Gentle","Calm","Tranquil","Passion","Mystery","Bright","Darkness","Dynamic","Playful ","Balance","Harmony","Majestic","Euphoric","Darkness","Peaceful","Ethereal ","Divine","Heavenly","Harmony","Radiant","Wrath","Vibrant","Darkness","Dynamic","Gentle","Calm","Tranquil","Passion","Mystery","Bright","Darkness","Vibrant","Dynamic","Playful","Balance","Harmony","Majestic","Bright","Euphoric","Peaceful","Dynamic","Darkness","Vibrant","Wrath","Mystery","Radiant","Harmony","Divine","Ethereal ","Peaceful","Darkness","Euphoric","Majestic","Harmony","Divine","Playful","Vibrant","Dynamic","Darkness","Bright","Mystery","Passion","Calm","Tranquil","Gentle","Ethereal ","Divine","Heavenly","Harmony","Radiant","Mystery","Wrath","Vibrant","Darkness","Dynamic","Gentle","Calm","Tranquil","Passion","Mystery","Bright","Darkness","Vibrant","Dynamic","Playful","Balance","Harmony","Majestic","Euphoric","Peaceful","Ethereal ","Divine","Heavenly","Harmony","Radiant","Mystery","Wrath","Vibrant","Darkness","Dynamic","Joy","Happiness","Sorrow","Bright","Dreamlike","Dynamic","Balance","Peaceful","Energetic","Ominous","Ghostly","Angelic","Calm","Serene","Euphoric","Melancholy","Mystery","Radiant","Ethereal ","Electric","Harmony","Vibrant","Tranquil","Divine","Heavenly","Mystical","Calm","Angelic","Ghostly","Divine","Heavenly","Serene","Peaceful","Dynamic","Dreamlike","Darkness","Playful","Bright","Sorrow","Joy","Happiness","Calm","Tranquil","Serene","Euphoric","Melancholy","Mystery","Radiant","Ethereal ","Electric","Harmony","Vibrant","Tranquil","Celestial","Whimsical"];
   
    function _getKieyaType(uint256 _index) internal view returns (uint16) {
        return KieyaType[_index];
    }

    function _getKieyaElement(uint256 _index) internal view returns (string memory) {
        return KieyaElement[_index];
    }
    
    function _getKieyaName(uint256 _index) internal view returns (string memory) {
        return KieyaName[_index];
    }
    
    function _getKieyaAura(uint256 _index) internal view returns (string memory) {
        return KieyaAura[_index];
    }

    function _randomIndices(uint256 count, uint256 cycleSeconds) internal view returns (uint256[] memory) {
        uint256[] memory numbers = new uint256[](count);
        for (uint256 j = 0; j < count; j++) {
            numbers[j] = j;
        }
        uint256 seed = uint256(
            keccak256(abi.encodePacked(block.timestamp / cycleSeconds )) 
        );
        for (uint256 i = 0; i < numbers.length; i++) {
            uint256 n = i + ((seed >> i) % (numbers.length - i));
            uint256 temp = numbers[n];
            numbers[n] = numbers[i];
            numbers[i] = temp;
        }
        return numbers;
    }
    
    function generateTokenURI(uint256 tokenId, string memory baseURI, bool jamaicaIsSunny, uint256 cycleSeconds) public view returns (string memory) {
        string memory imgUrl = 'https://static.wild.xyz/tokens/unrevealed/assets/unrevealed.webp';

        string memory stringTokenId = Strings.toString(tokenId);
        string memory attributesStr = '';
        string memory animationUrl = '';
        //string memory fileExt = '.png';
        uint256 _index = tokenId;

        if (bytes(baseURI).length > 0) {
            // if sunny in Jamaica and this is an even token,
            // switch MD/Video/Img with another even token
            // switch holds for 3 weeks.
            uint256[] memory listOfNumbers = _randomIndices(200, cycleSeconds);
            if (jamaicaIsSunny && tokenId % 2 == 0) {
                _index = listOfNumbers[tokenId];
                // if _index not even, subtract 1
                if (_index % 2 == 1) {
                    _index = _index - 1;
                }
            }
            // if not sunny in Jamaica and this is an odd token,
            // switch MD/Video/Img with another odd token
            else if (jamaicaIsSunny == false && tokenId % 2 == 1) {
                _index = listOfNumbers[tokenId];
                // if _index not odd, add 1
                if (_index % 2 == 0) {
                    _index = _index + 1;
                }

            }
            string memory stringIndex = Strings.toString(_index);
            imgUrl = string(abi.encodePacked(baseURI, 'KIEYA', stringIndex, '.png'));
            animationUrl = string(abi.encodePacked(baseURI, 'KIEYA', stringIndex, '.mp4'));
            string memory element = _getKieyaElement(_index);
            uint16 type_ = _getKieyaType(_index);
            string memory name = _getKieyaName(_index);
            string memory aura = _getKieyaAura(_index);
            attributesStr = string(abi.encodePacked(',"attributes":[{"trait_type":"Name","value":"', name, '"}, {"trait_type": "Element", "value":"', element, '"}, {"trait_type": "Aura", "value":"', aura, '"}, {"trait_type": "Type", "value":"', Strings.toString(type_), '"}]'));
        }
        
        string memory json;
        {
            string memory name = string(abi.encodePacked('KIEYA #', stringTokenId));
            string memory description = 'KIEYA is a collection of animated island spirits that are revived through the exchange of life. Employing generative artificial intelligence techniques, the collection tells an otherworldly science-fiction narrative extrapolating on a future techno-utopia.\n\nThe story begins in the year 7292. In this future Earth, books and physical forms of stories have become extinct. One day, a small meteorite lands in the ocean. Future humans discover that the meteorite contains particles of an advanced alien technology. Sparking a cyber-cultural revolution, the future ancestors use their discovery to create an artificial intelligence that ushers in not only a rebirth of storytelling for the world but also new methodologies for reviving art and creative visual expression.\n\nThey name the AI &#39;KIEYA&#39;, who becomes an art companion that offers collectors endless opportunities to own new lifeforms every month through &#39;the art of exchange&#39;. In this future, humanity believes that the best way to own art is to experience it changing over time through a randomized algorithmic function. Once KIEYA is collected, the spirit token will leave and switch to another holder every 22 days. In this speculative art-centered reality, the constant exchange of experience enriches the human race exponentially, leading to a renaissance of creativity and connection.\n\nThe collection is inspired by Nygilia&#39;s grandmother&#39;s German shepherd &#39;Kieya&#39;, who protected her outside while playing as a child. Kieya was like a guardian, enabling Nygilia to explore the world and learn with a safe and benevolent companion. Throughout the collection, Nygilia employs her uniquely magical use of character creation, rooting the viewer&#39;s experience in a rich exploration of posthumanism through the lens of Afro-Caribbean futurity. Each spirit is completely unique, with its own shape, animation, and texture. Like Nygilia&#39;s Kieya, KIEYA is an ephemeral friend that keeps coming to you, safeguarding your wallet as you explore the unpredictable open sea of Web3.';
            string memory externalUrl = string.concat('https://wild.xyz/nygilia/kieya/', stringTokenId);
            
            json = Base64.encode(bytes(abi.encodePacked('{"name":"', name, '", "description": "', description, '", "image": "', imgUrl, '", "animation_url": "', animationUrl, '", "external_url": "', externalUrl, '"', attributesStr, '}')));
        }
        
        return string(abi.encodePacked('data:application/json;base64,', json));
    }
}