# FOOP Tracker

Production, harvest and sales tracker for the FOOP greenhouses in Tormabum, Sierra Leone.

One shared app for the whole team: the field staff log plants and harvest, the sales
colleague logs market sales, and managers see everything — all on the same data,
from any phone.

---

## What's in this repo

| File | What it is |
|---|---|
| `index.html` | The whole app (one file). |
| `supabase_setup.sql` | Run once to build the database. |
| `manifest.json`, `icon.svg` | Lets the app install on a phone home screen. |
| `netlify.toml` | Netlify settings. |

---

## Roles

| Role | Can see | Cannot see |
|---|---|---|
| **Field** | Dashboard, Data, Estimations, Harvest | Anything about sales or money |
| **Sales** | Dashboard, Sales (record sales, market prices) | Plant/harvest data entry |
| **Manager** | Everything, including the Scenarios market comparison | — |

Everyone has their own account (email + password) and is given a role. Permissions are
enforced by the database (Row Level Security), not just hidden on screen — the Field
role genuinely cannot read the sales table. Because each person has their own login,
you can see who entered what and remove one person without disturbing anyone else.

---

## Setup (do this once)

### 1. Create the database

1. Go to [supabase.com](https://supabase.com) and open your project.
2. Open **SQL Editor → New query**.
3. Paste the whole contents of `supabase_setup.sql` and press **Run**.

### 2. Create one account per person

In Supabase go to **Authentication → Users → Add user**, with **Auto Confirm User** ON.
Use each person's **real email address** so that "forgot my password" works.
Passwords must be at least 6 characters.

Create one account per person, for example:

| Email | Role |
|---|---|
| `calvin@foop.org` | manager |
| `karen@foop.org` | manager |
| *(sales colleague)* | sales |
| *(field staff)* | field |

Then copy each user's **UID** from the users list and run this in the SQL Editor:

```sql
insert into public.profiles (id, role, name) values
  ('PASTE-CALVIN-UID', 'manager', 'Calvin'),
  ('PASTE-KAREN-UID',  'manager', 'Karen'),
  ('PASTE-SALES-UID',  'sales',   'Sales colleague'),
  ('PASTE-FIELD-UID',  'field',   'Field staff');
```

The role comes from this table, never from the email address. Someone who signs in
without a row here is refused and told to ask a manager.

**Later on:**

```sql
-- change someone's role
update public.profiles set role = 'manager' where id = 'THEIR-UID';
```

To remove access, delete the user in **Authentication → Users**. Nobody else is affected.

### 3. Connect the app to the database

In Supabase, open **Project Settings → API** and copy the **Project URL** and the
**anon public** key.

Open `index.html` and edit the two lines near the top of the script:

```js
const SUPABASE_URL      = "https://YOUR-PROJECT.supabase.co";
const SUPABASE_ANON_KEY = "PASTE-YOUR-ANON-PUBLIC-KEY-HERE";
```

Save and upload the file again.

> The anon key is safe to publish — it only grants what the security rules allow.
> **Never** put the `service_role` key in this file.

### 4. Publish

**Netlify:** drag the repo folder onto your existing site, or connect the GitHub repo
(no build command needed — it's a static file).

**GitHub Pages:** Settings → Pages → Source: `main`, folder `/root`.

### 5. Put it on the phones

Open the site in Chrome (Android) or Safari (iPhone) → **Share → Add to Home Screen**.
It then behaves like an app. Each person signs in once on their own phone.

---

## Daily use

**Field team**
- *Data → Plant batches*: add a batch when something new is planted.
- Tap a batch when plants die and enter how many. Losses are counted automatically
  for that week — no separate tally to keep.
- *Data → This week's record*: enter kg harvested per crop, plus nursed and
  transplanted counts, then **Save week**.

**Sales**
- *Sales → Record a sale*: date, market, crop, kg delivered, kg sold, price.
  Transport, net revenue and spoilage are calculated automatically.
- Add the **voucher / tracking number** so each delivery can be traced.
- *Market prices*: update when the market survey changes.

**Managers**
- *Dashboard*: the numbers for donor and CEO reporting.
- *Harvest*: projection vs actual, overall and per crop.
- *Sales → Scenarios*: which market pays best for each crop after transport.

---

## Working without internet

The app keeps a copy of the data on the phone. If the signal drops:

- everything is still readable;
- new entries are saved on the phone and a bar shows how many are waiting;
- when the signal comes back they upload automatically.

Keep the app open until the offline bar disappears.

---

## Things to know

- **The free Supabase plan pauses a project after ~7 days without activity.**
  If nobody uses the app for a week, open the Supabase dashboard and press
  **Restore project**. There is a 90-day limit before a paused project is removed,
  so don't leave it asleep for months.
- **The free plan has no automatic backups.** Export a copy from time to time
  (Supabase → Table Editor → export as CSV).
- **Forgotten password:** tap "Forgot my password" on the sign-in screen — the reset
  link is emailed to that person. A manager can also reset it from
  Supabase → Authentication → Users.
- **Signing in happens once per phone.** The session stays open afterwards, so there is
  no daily login. Use the button at the top right to sign out or switch person.
- **To change the dashboard targets** (plants in production / nursery):
  ```sql
  update public.settings
     set value = '{"prod":400,"nursery":200}'::jsonb
   where key = 'targets';
  ```

---

## Yield assumptions

Estimates use conservative kg-per-plant figures for Sierra Leone field conditions,
not greenhouse-ideal numbers — it is better to under-promise to donors and beat the
estimate. They can be edited in the app (*Estimations* tab) and the change is shared
with the whole team.
