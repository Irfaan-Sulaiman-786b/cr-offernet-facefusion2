from typing import Optional

METADATA =\
{
	'name': 'Offerrnet+FaceFusion',
	'description': 'Industry leading face manipulation platform',
	'version': '0.1.1',
	'license': 'MIT',
	'author': 'Henry Ruhs',
	'url': 'https://facefusion.io'
}


def get(key : str) -> Optional[str]:
	if key in METADATA:
		return METADATA.get(key)
	return None
