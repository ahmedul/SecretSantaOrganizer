import random

def derange(names: list[str]) -> dict[str, str] | None:
    n = len(names)
    if n < 2:
        return None
    max_attempts = 1000
    for _ in range(max_attempts):
        targets = names[:]
        random.shuffle(targets)
        if all(targets[i] != names[i] for i in range(n)):
            return dict(zip(names, targets))
    return None

def derange_with_exclusions(participants: list, exclusions: set[tuple]) -> dict | None:
    names = [p.name for p in participants]
    max_attempts = 1000
    for _ in range(max_attempts):
        d = derange(names)
        if d is None:
            return None
        valid = True
        for giver, receiver in d.items():
            giver_idx = names.index(giver)
            receiver_idx = names.index(receiver)
            if (participants[giver_idx].id, participants[receiver_idx].id) in exclusions:
                valid = False
                break
        if valid:
            return {p.id: next(t.id for t in participants if t.name == d[p.name]) for p in participants}
    return None
